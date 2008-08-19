module MythTV

  # The class used to represent events in the EPG
  class Program

    PROGRAM_ELEMENTS = [ :parent, :programFlags, :title, :programId, :catType,
                         :category, :seriesId, :endTime, :lastModified, :subTitle,
                         :stars, :repeat, :fileSize, :startTime, :hostname,
                         :airdate, :description ]
    
    attr_accessor *PROGRAM_ELEMENTS
    
    def initialize
    end

    # Debugging method
    def to_s
      PROGRAM_ELEMENTS.collect { |v| "#{v}: '#{self.send(v) || 'nil'}'" }.join(", ")
    end
    
  end  

end