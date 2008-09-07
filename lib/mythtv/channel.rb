module MythTV
  
  class Channel
    
    # Columns from the database
    DATABASE_COLUMNS = [ :chanid, :channum, :freqid, :sourceid, :callsign, :name, :icon, :finetune,
                         :videofilters, :xmltvid, :recpriority, :contrast, :brightness, :colour,
                         :hue, :tvformat, :commfree, :visible, :outputfilters, :useonairguide,
                         :mplexid, :serviceid, :atscsrcid, :tmoffset, :atsc_major_chan,
                         :atsc_minor_chan, :last_record, :default_authority, :commmethod ]
    
    attr_accessor(*DATABASE_COLUMNS)

    # Construct a new instamce by passing in an array of elements, whos length,
    # and order are the same as those set out in the Channel::DATABASE_COLUMNS array
    # 
    def initialize(channel_array, db_instance)
      DATABASE_COLUMNS.each_with_index do |col, i|
        send("#{col}=", channel_array[i])
      end
      
      @db = db_instance
    end
  
    # Create a to_s method to help with debugging
    def to_s; DATABASE_COLUMNS.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
    
  end
  
end