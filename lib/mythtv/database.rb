require 'mysql'

module MythTV
  
  class Database
    
    attr_accessor :connection
    
    def initialize(options = {})
      default_options = { :database_name => 'mythconverg', :database_host => :host }
      
      return nil unless options.has_key?(:database_user) && options.has_key?(:database_password)
      
      options = default_options.merge(options)
      
      @database_host = options[:database_host] == :host ? options[:host] : options[:database_host]
      @database_name = options[:database_name]
      @database_user = options[:database_user]
      @database_password = options[:database_password]
      
      @connection = Mysql.real_connect(@database_host, @database_user, @database_password, @database_name)
      puts @connection.get_server_version()
    end
    
    def get_setting(value, hostname = '')
      query = "SELECT value FROM settings WHERE value = ?"
      query += " AND hostname = ?" unless hostname == ''
      
      st = @connection.prepare(query)
      
      begin
        hostname == '' ? st.execute(value) : st.execute(value, hostname)

        raise ArgumentError, "More than one corresponding setting row found" if st.num_rows > 1

        # If we haven't found anything, return now
        data = st.num_rows == 0 ? nil : st.fetch[0]
      ensure
        # Make sure we close the statement object nicely
        st.close
      end

      data
    end
    
  end
end