module MythTV
  
  class Program

    def initialize(program_array, db_instance)
      # Find out the attributes this class has from the schema calculations earlier
      columns = db_instance.table_columns[self.class]
      
      self.class.class_eval { attr_accessor(*columns) }
      
      @columns = columns

      @columns.each_with_index do |col, i|
        self.send("#{col}=", program_array[i])
      end
      
      @db = db_instance
    end
    
    def to_s; @columns.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
  
    def channel
      channels = @db.list_channels(:conditions => ['chanid = ?', self.chanid])
      if channels.length == 1
        channels[0]
      else
        nil
      end
    end
  end
  
end
