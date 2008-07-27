module MythTV

  # The class used to represent events in the EPG
  class Program

    attr_accessor :programFlags, :title, :programId, :catType, :category
    attr_accessor :seriesId, :endTime, :lastModified, :subTitle, :stars
    attr_accessor :repeat, :fileSize, :startTime, :hostname, :airdate
    attr_accessor :description
    
    def initialize
    end

  end  

end