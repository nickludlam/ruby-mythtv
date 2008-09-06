require 'rexml/document'

module MythTV

  # The factory class which processes the XML guide data from the
  # MythTV::Backend#get_program_guide() method. It will generate an array
  # of MythTV::XMLChannel objects, which in turn contain a number of
  # MythTV::XMLProgram instances for each program/event found
  class XMLEPG

    # This method requires the XML guide data obtained from
    # MythTV::Backend#get_program_guide()
    def self.process_guide_xml(guide_xml)
      channels = []
      
      doc = REXML::Document.new(guide_xml)
      channel_obj = nil
      
      REXML::XPath.each( doc, "//Channel/Program") do |program|
        program_attributes  = program.attributes
        program_description = program.text
        
        channel = program.parent
        channel_attributes = program.parent.attributes
        
        # Check for existing channel, and if not, create one
        unless channel_obj = channels.find { |c| c.chanNum == channel_attributes.get_attribute('chanNum').value }
          channel_obj = MythTV::XMLChannel.new
          channel_attributes.each { |key, value| channel_obj.send(key + '=', channel.attributes[key]) }
          channels << channel_obj
        end
        
        # Construct the program object to correspond to the XPath match
        program_obj = MythTV::XMLProgram.new
        program_obj.parent = channels[-1] # Make a link back to the parent channel object
        program_attributes.each { |key, value| program_obj.send(key + '=', program.attributes[key]) }
        program_obj.description = program_description
        
        channel_obj.programs << program_obj
      end
      
      channels
    end
    
  end
  
  # The class used to represent a channel, and contain events from
  # an EPG listing. See MythTV::XMLEPG
  class XMLChannel
    
    attr_accessor :programs
    
    attr_accessor :chanFilters, :channelName, :chanNum, :sourceId
    attr_accessor :commFree, :inputId, :enchanId, :callSign, :chanId

    def initialize
      # Channels hold Program instances
      @programs = []
    end
  
  end
  
  
  # The class used to represent events in the EPG. See MythTV::XMLEPG
  class XMLProgram

    PROGRAM_ELEMENTS = [ :parent, :programFlags, :title, :programId, :catType,
                         :category, :seriesId, :endTime, :lastModified, :subTitle,
                         :stars, :repeat, :fileSize, :startTime, :hostname,
                         :airdate, :description ]
    
    attr_accessor *PROGRAM_ELEMENTS
    
    def initialize
    end

    # Debugging method
    def to_s
      PROGRAM_ELEMENTS.collect { |v| "#{v}: '#{send(v) || 'nil'}'" }.join(", ")
    end
    
  end
  
end
