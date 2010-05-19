require 'rubygems'
require 'active_record'
ActiveRecord::ActiveRecordError # Workaround for this bug: https://rails.lighthouseapp.com/projects/8994/tickets/2577-when-using-activerecordassociations-outside-of-rails-a-nameerror-is-thrown
require 'composite_primary_keys'
require 'mysql'

module MythTV
  
  class Database
    
    # Initialise and connect to the MySQL server
    #
    # Required keys in options[] are:
    #
    # :database_host (or :host) => The target server address or name
    # :database_user            => The username used to connect to the MythTV MySQL database
    # :database_password        => The password used to connect to the MythTV MySQL database
    #
    # Optional keys:
    #
    # :database_name => Defaults to 'mythconverg' unless specified
    # :log_output    => A Ruby Logger output. Defaults to STDERR
    # :log_level     => A Ruby Logger log level. Defaults to Logger::WARN
    def initialize(options)
      default_options = { :database_user => 'mythtv',
                          :database_name => 'mythconverg',
                          :database_host => :host,
                          :database_port => 3306 }
      
      options = default_options.merge(options)
      
      @database_host = options[:database_host] == :host ? options[:host] : options[:database_host]
      @database_name = options[:database_name]
      @database_user = options[:database_user]
      @database_port = options[:database_port]
      @database_password = options[:database_password]
      
      @connection_details = {
        :adapter => 'mysql',
        :host => @database_host,
        :port => @database_port,
        :database => @database_name,
        :username => @database_user,
        :password => @database_password
      }
      
      # Establish our connections specifically for the ruby-mythtv module
      # TODO: I'm not particularly happy about this, as I'd rather it was done
      #       on demand, but at the moment it's not clear how you share nicely
      #       with other ActiveRecord instances talking to other databases
      MythTV::Channel.establish_connection(@connection_details)
      MythTV::Program.establish_connection(@connection_details)
      MythTV::RecordingSchedule.establish_connection(@connection_details)
      MythTV::Setting.establish_connection(@connection_details)
      
      # Set up a local logging object
      @log = MythTV::Utils.setup_logging(options)
      
      # Although we don't need to give back an instance, as we now work through
      # class methods, we pass back self for the constructor
      self
    end
  end
end