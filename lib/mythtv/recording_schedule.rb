module MythTV
  
  class RecordingSchedule < ActiveRecord::Base
    set_table_name 'record'
    set_primary_key 'recordid'
    set_inheritance_column nil

    belongs_to :channel, :foreign_key => 'chanid', :class_name => "MythTV::Channel"
    
    # Map the 'type' column to a string
    RS_TYPE_MAP = { 0 => :kNotRecording,
                    1 => :kSingleRecord,
                    2 => :kTimeslotRecord,
                    3 => :kChannelRecord,
                    4 => :kAllRecord,
                    5 => :kWeekslotRecord,
                    6 => :kFindOneRecord,
                    7 => :kOverrideRecord,
                    8 => :kDontRecord,
                    9 => :kFindDailyRecord,
                   10 => :kFindWeeklyRecord }
    
    #
    RS_DUPIN_MASK = { :kDupsInRecorded    => 0x01,
                      :kDupsInOldRecorded => 0x02,
                      :kDupsInAll         => 0x0F,
                      :kDupsNewEpi        => 0x10,
                      :kDupsExRepeats     => 0x20,
                      :kDupsExGeneric     => 0x40,
                      :kDupsFirstNew      => 0x80 }
    #
    RS_DUPMETHOD_MASK = { :kDupCheckNone        => 0x01,
                          :kDupCheckSub         => 0x02,
                          :kDupCheckDesc        => 0x04,
                          :kDupCheckSubDesc     => 0x06,
                          :kDupCheckSubThenDesc => 0x08 }
    
    #
    COLUMN_TO_ENUM_MAP = { :type      => RS_TYPE_MAP,
                           :dupmethod => RS_DUPIN_MASK,
                           :dupmethod => RS_DUPMETHOD_MASK }
    #
    def initialize(options = nil)
      super()
      
      default_options = { :type => 6, # Find one of...
                          :profile => 'Default',
                          :recpriority => 0,
                          :autoexpire =>  MythTV::Setting.data_for_value('AutoExpireDefault'),
                          :maxepisodes => 0,
                          :maxnewest => 0,
                          :startoffset => MythTV::Setting.data_for_value('DefaultStartOffset'),
                          :endoffset => MythTV::Setting.data_for_value('DefaultEndOffset'),
                          :recgroup => 'Default',
                          :dupmethod => 6, # 
                          :dupin => 15,
                          :search => 0,
                          :autotranscode => MythTV::Setting.data_for_value('AutoTranscode'),
                          :autocommflag => MythTV::Setting.data_for_value('AutoCommercialFlag'),
                          :autouserjob1 => MythTV::Setting.data_for_value('AutoRunUserJob1'),
                          :autouserjob2 => MythTV::Setting.data_for_value('AutoRunUserJob2'),
                          :autouserjob3 => MythTV::Setting.data_for_value('AutoRunUserJob3'),
                          :autouserjob4 => MythTV::Setting.data_for_value('AutoRunUserJob4'),
                          :findday => 0,
                          :findtime => 0,
                          :findid => 0,
                          :inactive => 0,
                          :parentid => 0,
                          :transcoder => MythTV::Setting.data_for_value('DefaultTranscoder'),
                          :tsdefault => 1,
                          :playgroup => 'Default',
                          :prefinput => 0,
                          :next_record => Time.at(0),
                          :last_record => Time.at(0),
                          :last_delete => Time.at(0),
                          :storagegroup => 'Default',
                          :avg_delay => 0 }
      
      # TODO: The logic here isn't very clean. More DRY needed!
      
      # We can be passed a Hash, or an instance of Program. In the Hash case, we
      # merge the specified options in with the defaults before assignment happens
      if options.is_a?(MythTV::Program) || options.nil?
        program = options
        merged_options = default_options
      elsif options.class == Hash
        program = nil
        merged_options = default_options.merge(options)
      end
      
      # Assign the options to self
      merged_options.each_pair do |k, v|
        self.send("#{k.to_s}=", v)
      end
      
      # If we've been passed a Program, we do some work to set up things up accordingly
      if program
        self.chanid = program.chanid
        self.starttime = program.starttime
        self.startdate = program.starttime
        self.endtime = program.endtime
        self.enddate = program.endtime
        self.title = program.title
        self.subtitle = program.subtitle
        self.description = program.description
        self.category = program.category
        self.seriesid = program.seriesid
        self.programid = program.programid

        # Station assignment from the channel object. Needs caching?
        channel = MythTV::Channel.find(self.chanid).name
      end
      
    end

  end
  
end

