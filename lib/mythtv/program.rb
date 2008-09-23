module MythTV
  
  class Program
    
    # Columns from the database
    DATABASE_COLUMNS = [ :chanid, :starttime, :endtime, :title, :subtitle, :description, :category,
                         :category_type, :airdate, :stars, :previouslyshown, :title_pronounce,
                         :stereo, :subtitled, :hdtv, :closecaptioned, :partnumber, :parttotal,
                         :seriesid, :originalairdate, :showtype, :colorcode, :syndicatedepisodenumber,
                         :programid, :manualid, :generic, :listingsource, :first, :last, :audioprop,
                         :subtitletypes, :videoprop ]
    
    attr_accessor(*DATABASE_COLUMNS)
    
    def initialize(program_array, db_instance)
      DATABASE_COLUMNS.each_with_index do |col, i|
        send("#{col}=", program_array[i])
      end
      
      @db = db_instance
    end
    
    def to_s; DATABASE_COLUMNS.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", "); end
  
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