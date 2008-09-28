module MythTV
  
  class Channel
    # Construct a new instamce by passing in an array of elements, whos length,
    # and order are the same as those set out in the columns mapping for Channel
    # 
    def initialize(channel_array, db_instance)
      # Find out the attributes this class has from the schema calculations earlier
      columns = db_instance.table_columns[self.class]
      
      self.class.class_eval { attr_accessor(*columns) }
      
      @columns = columns
      
      @columns.each_with_index do |col, i|
        self.send("#{col}=", channel_array[i])
      end
      
      @db = db_instance
    end
  
    # Create a to_s method to help with debugging
    def to_s; @columns.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
    
  end
  
end