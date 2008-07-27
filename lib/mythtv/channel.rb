module MythTV
  
  # The class used to contain events within an EPG listing
  class Channel
    
    attr_accessor :programs
    
    attr_accessor :chanFilters, :channelName, :chanNum, :sourceId
    attr_accessor :commFree, :inputId, :enchanId, :callSign, :chanId

    def initialize
      # Channels hold Program instances
      @programs = []
    end
  
  end
    
end
