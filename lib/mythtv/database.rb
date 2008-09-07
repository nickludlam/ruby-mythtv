require 'rubygems'
require 'mysql'

module MythTV
  
  class Database

    attr_accessor :connection
    attr_accessor :setting_cache
    
    TABLE_TO_CLASS_MAP = { 'channel' => MythTV::Channel,
                           'program' => MythTV::Program,
                           'record'  => MythTV::RecordingSchedule }
    
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
    def initialize(options)
      # Initialise the settings cache for later use in the get_setting() method
      @setting_cache = {}
      
      default_options = { :database_name => 'mythconverg', :database_host => :host }
      
      return nil unless options.has_key?(:database_user) && options.has_key?(:database_password)
      
      options = default_options.merge(options)
      
      @database_host = options[:database_host] == :host ? options[:host] : options[:database_host]
      @database_name = options[:database_name]
      @database_user = options[:database_user]
      @database_password = options[:database_password]
      
      @connection = Mysql.real_connect(@database_host, @database_user, @database_password, @database_name)
      
      # Create a mapping of Fixnum -> CONSTANT to dereference the Mysql::Field#type() method output
      #
      # Types are:
      # TYPE_DECIMAL = 0
      # TYPE_TINY = 1
      # TYPE_SHORT = 2
      # TYPE_LONG = 3
      # TYPE_FLOAT = 4
      # TYPE_DOUBLE = 5
      # TYPE_NULL = 6
      # TYPE_TIMESTAMP = 7
      # TYPE_LONGLONG = 8
      # TYPE_INT24 = 9
      # TYPE_DATE = 10
      # TYPE_TIME = 11
      # TYPE_DATETIME = 12
      # TYPE_YEAR = 13
      # TYPE_NEWDATE = 14
      # TYPE_ENUM = 247
      # TYPE_SET = 248
      # TYPE_TINY_BLOB = 249
      # TYPE_MEDIUM_BLOB = 250
      # TYPE_LONG_BLOB = 251
      # TYPE_BLOB = 252
      # TYPE_VAR_STRING = 253
      # TYPE_STRING = 254
      # TYPE_GEOMETRY = 255
      # TYPE_CHAR = TYPE_TINY
      # TYPE_INTERVAL = TYPE_ENUM
      #
      column_type_map = Hash.new
      Mysql::Field.constants.each do |cname|
        if (cname =~ /^TYPE_/)
          cval = Mysql::Field.const_get(cname)
          column_type_map[cval] = cname if cval.class == Fixnum
        end
      end
      
      # Cache the various table's column types for easy lookup
      @column_type_cache = {}
      
      ["channel", "program", "record"].each do |table|
        @column_type_cache[table] = {}
        
        result = @connection.list_fields(table)
        # Create a hash mapping in the appropriate table hash, which
        # maps the column name to the dereferenced column type CONSTANT
        while field = result.fetch_field()
          @column_type_cache[table][field.name()] = column_type_map[field.type()]
        end
        
      end
      
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
      
      st_query =  "SELECT " + MythTV::Channel::DATABASE_COLUMNS.collect { |c| c.to_s }.join(",") + " FROM channel"      
      
      (converted_query, st_args) = simple_options_to_sql(options, 'channel')
      st_query += converted_query

      puts "QUERY: #{st_query}"
      
      # Execute the statement, and create the Channel objects from the results
      st = @connection.prepare(st_query)
      results = st.execute(*st_args)
      channels = []
      st.num_rows.times { channels << Channel.new(st.fetch) }
      
      channels
    end
    
    def list_programs(options = {})
      default_options = { :order => "starttime ASC" }
      
      # Merge in our defaults with what we've been given
      options = default_options.merge(options)
      
      st_query =  "SELECT " + MythTV::Program::DATABASE_COLUMNS.collect { |c| c.to_s }.join(",") + " FROM program"
      
      (converted_query, st_args) = simple_options_to_sql(options, 'program')
      st_query += converted_query
      
      puts "QUERY: #{st_query}"
      
      # Execute the statement, and create the Channel objects from the results
      st = @connection.prepare(st_query)
      results = st.execute(*st_args)
      programs = []
      st.num_rows.times { programs << Program.new(st.fetch) }
      
      programs
    end
    
    def list_recording_schedules(options = {})
    end
  
  private
  
    # A simple method which allows the presence of a key in the options array which matches
    # a column in the table to be turned into a simple equality statement, or IN statement.
    #
    # If the value class is an array, the resulting statement is of the form "<col> IN (?, ?...)"
    #
    # In all other cases, the resulting statement is of the form "<co> = ?"
    def simple_options_to_sql(options, table_name)
      where_query = []     # Accumulate statements here, and join with " AND " after
      where_args  = []     # Accumulate substitution variables here
      assembled_query = "" # Final output SQL goes in here
      
      # Turn the name of the table into a class reference, and find the column defs
      table_columns = TABLE_TO_CLASS_MAP[table_name].const_get('DATABASE_COLUMNS')
      
      options.each_pair do |key, value|
        if table_columns.include?(key)
          # If we have been given a key which corresponds to a column
          if value.class == Array
            # If it's an array, we substitute in a '?' in the statement for every element
            where_query << "#{key} IN (" + (['?'] * value.length).join(",") + ")"
            where_args += value
          if value.class == Regexp
            where_query << "#{key} LIKE ?"
            where_args << value
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
      if options.has_key?(:where) && options[:where].class == Array
        where_query << options[:where].shift
        where_args += options[:where]
      end
      
      # Assemble the fragments around WHERE and AND, if we need to
      if where_query.length > 0
        assembled_query += " WHERE " + where_query.join(" AND ")
      end
      
      # Allow specification of an ORDER column and direction
      if options.has_key?(:order)
        assembled_query += " ORDER BY #{options[:order]}"
      end
      
      # Allow limiting of returned results
      if options.has_key?(:limit)
        assembled_query += " LIMIT #{options[:limit]}"
      end

      return [assembled_query, where_args]
    end
  
  
  end
end