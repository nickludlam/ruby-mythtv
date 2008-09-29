require 'rubygems'
require 'mysql'

module MythTV
  
  class Database

    attr_accessor :connection     # The MySQL connection object
    attr_accessor :setting_cache  # The Hash which stores previously retrieved settings
    attr_accessor :table_columns  # The Hash which contains the column info for the tables
    
    TABLE_TO_CLASS_MAP = { 'channel' => Channel,
                           'program' => Program,
                           'record'  => RecordingSchedule }
    
    # Initialise and connect to the MySQL server
    #
    # Required keys in options[] are:
    #
    # :database_user => The username to connect to the mysql database as
    # :database_password => The password to connect to the mysql database with
    #
    # Optional keys:
    #
    # :database_host => Defaults to the same value as the backend host, unless specified
    # :database_name => Defaults to 'mythconverg' unless specified
    # :log_output    => A Ruby Logger output. Defaults to STDERR
    # :log_level     => A Ruby Logger log level. Defaults to Logger::WARN
    def initialize(options)
      # Initialise the caches for later use
      @setting_cache = {}
      
      default_options = { :database_user => 'mythtv', :database_name => 'mythconverg', :database_host => :host }
      
      raise ArgumentError, ":database_password must be a key within the options argument Hash" unless options.has_key?(:database_password)
      
      options = default_options.merge(options)
      
      @database_host = options[:database_host] == :host ? options[:host] : options[:database_host]
      @database_name = options[:database_name]
      @database_user = options[:database_user]
      @database_password = options[:database_password]
      
      @connection = Mysql.real_connect(@database_host, @database_user, @database_password, @database_name)
      
      # Set up a local logging object
      @log = MythTV::Utils.setup_logging(options)
      
      # Query the schema version, and calculate the columns in Channel, Program, and RecordingSchedule
      @table_columns = {
        Channel => process_dbschemaver(:channel),
        Program => process_dbschemaver(:program),
        RecordingSchedule => process_dbschemaver(:recording_schedule)
      }
    end
    
    # Close the database connection properly
    def close()
      @connection.close() if @connection
    end
    
    # Fetch the stored setting from the settings database table, for the specified value field
    def get_setting(value, hostname = '')
      # Construct a unique key. Fetch from cache if present
      key = value + "_" + hostname
      return @setting_cache[key] if @setting_cache.has_key?(key)
      
      query = "SELECT data FROM settings WHERE value = ?"
      # If we're explicitly given a value for hostname, then make this part of
      # the WHERE condition
      query += " AND hostname = ?" unless hostname == ''

      st = @connection.prepare(query)

      begin
        hostname == '' ? st.execute(value) : st.execute(value, hostname)
        # We shouldn't get multiple matches, so check and raise an exception if necessary
        raise ArgumentError, ("Too many matches! %d matching rows found for '%s'" % [st.num_rows, value]) if st.num_rows > 1

        # If we haven't found anything, return now
        data = st.num_rows == 0 ? nil : st.fetch[0]
      ensure
        # Make sure we close the statement object nicely
        st.close
      end

      # Set in the cache before we return the value
      @setting_cache[key] = data
      
      data
    end
    
    # Return an array of Channel objects, selected by the criteria set out in
    # the options hash.
    #
    def list_channels(options = {})
      default_options = { :order => "chanid ASC" }
      
      # Merge in our defaults with what we've been given
      options = default_options.merge(options)
      
      st_query =  "SELECT " + @table_columns[Channel].collect { |c| c.to_s }.join(",") + " FROM channel"      
      
      (converted_query, st_args) = simple_options_to_sql(options, 'channel')
      st_query += converted_query
      
      @log.debug("CHANNEL QUERY: #{st_query}")
      
      # Execute the statement, and create the Channel objects from the results
      st = @connection.prepare(st_query)
      results = st.execute(*st_args)
      channels = []
      st.num_rows.times { channels << Channel.new(st.fetch, self) }
      
      channels
    end
    
    def list_programs(options = {})
      default_options = { :order => "starttime ASC" }
      
      # Merge in our defaults with what we've been given
      options = default_options.merge(options)
      
      st_query =  "SELECT " + @table_columns[Program].collect { |c| c.to_s }.join(",") + " FROM program"
      
      (converted_query, st_args) = simple_options_to_sql(options, 'program')
      st_query += converted_query
      
      @log.debug("PROGRAM QUERY: #{st_query}")
      
      # Execute the statement, and create the Channel objects from the results
      st = @connection.prepare(st_query)
      results = st.execute(*st_args)
      programs = []
      st.num_rows.times { programs << Program.new(st.fetch, self) }
      
      programs
    end
    
    def list_recording_schedules(options = {})
      default_options = { :order => "recordid ASC" }
      
      # Merge in our defaults with what we've been given
      options = default_options.merge(options)
      
      st_query =  "SELECT " + @table_columns[RecordingSchedule].collect { |c| c.to_s }.join(",") + " FROM record"
      
      (converted_query, st_args) = simple_options_to_sql(options, 'record')
      st_query += converted_query
      
      @log.debug("RECORD QUERY: #{st_query}")
      
      # Execute the statement, and create the Channel objects from the results
      st = @connection.prepare(st_query)
      results = st.execute(*st_args)
      recording_schedules = []
      st.num_rows.times { recording_schedules << RecordingSchedule.new(st.fetch, self) }
      
      recording_schedules
    end
  
  private
    # We need to work out what schema version the database is, and derive the columns
    # present for each of the database tables represented in Channel, Program and RecordingSchedule
    def process_dbschemaver(class_name_sym)
      # First get the DBSchemaVer of the database we're talking to
      schema_version = get_setting('DBSchemaVer').to_i
      
      #@log.debug("Got schema_version #{schema_version}")

      base_columns_const_name = class_name_sym.to_s.upcase + "_BASE_COLUMNS"
      # Duplicate this for schema change processing
      table_columns = MythTV.const_get(base_columns_const_name).dup

      #@log.debug("base table_columns are: #{table_columns.inspect}")
      
      # Find any schema changes for this version of the DBSchemaVer
      schema_changes_const_name = class_name_sym.to_s.upcase + "_SCHEMA_CHANGES"
      schema_changes = MythTV.const_get(schema_changes_const_name)
      
      # Process the :push and :remove keys appropriately
      if schema_changes.has_key?(schema_version)
        @log.debug("Schema mapping found. Applying changes to the column layout")
        schema_changes[schema_version].each_pair do |action, columns|
          columns.map do |column|
            table_columns.send(action, column)
          end
        end
      end

      #@log.debug("Returning column array #{table_columns.inspect}")
      table_columns
    end
  
  
    # A simple method which allows the presence of a key in the options array which matches
    # a column in the table to be turned into a simple equality statement, or IN statement.
    #
    # If the value class is an array, the resulting statement is of the form "<col> IN (?, ?...)"
    #
    # In all other cases, the resulting statement is of the form "<co> = ?"
    #
    # Also allows specification of :conditions, :order and :limit, which emulate their
    # ActiveRecord counterparts
    def simple_options_to_sql(options, table_name)
      where_query = []     # Accumulate statements here, and join with " AND " after
      where_args  = []     # Accumulate substitution variables here
      assembled_query = "" # Final output SQL goes in here
      
      # Turn the name of the table into a class reference, and find the column defs
      table_columns = @table_columns[TABLE_TO_CLASS_MAP[table_name]]
      
      options.each_pair do |key, value|
        if table_columns.include?(key)
          # If we have been given a key which corresponds to a column
          if value.class == Array
            # If it's an array, we substitute in a '?' in the statement for every element
            where_query << "#{key} IN (" + (1..value.length).map {'?'}.join(',') + ")"
            where_args += value
          else
            where_query << "#{key} = ?"
            where_args << value
          end
        end
      end
      
      # Custom where clauses are specified with an array, with the first
      # element being the statement to pass to prepare(), and the second being
      # the arguments for that statement fragment.
      #
      # ie/  :where => ["starttime BETWEEN ? AND ?", Time.now, Time.now + 3600]
      if options.has_key?(:conditions) && options[:conditions].class == Array
        where_query << options[:conditions].shift
        where_args += options[:conditions] if options[:conditions].length > 0
      end
      
      # Assemble the fragments around WHERE and AND, if we need to
      if where_query.length > 0
        assembled_query += " WHERE #{where_query.join(" AND ")}"
      end
      
      # Allow specification of an ORDER column and direction
      if options.has_key?(:order)
        assembled_query += " ORDER BY #{options[:order]}"
      end
      
      # Allow limiting of returned results
      if options.has_key?(:limit)
        assembled_query += " LIMIT #{options[:limit]}"
      end

      [assembled_query, where_args]
    end
  
  end
end