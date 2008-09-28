require File.dirname(__FILE__) + '/test_helper.rb'

class TestDatabase < Test::Unit::TestCase
  def setup
    abort("\n\tmyERROR: You must set the environment variable MYTHTV_DB to the name of your MythTV database server\n\n") unless ENV['MYTHTV_DB']
    abort("\n\tmyERROR: You must set the environment variable MYTHTV_PW to the name of your MythTV database server\n\n") unless ENV['MYTHTV_PW']
    @db = MythTV.connect_database(:host => ENV['MYTHTV_DB'],
                                  :database_user => 'mythtv',
                                  :database_password => ENV['MYTHTV_PW'],
                                  :log_level => Logger::DEBUG)
  end
  
  def teardown
    @db.close
  end
  
  # Check the DBSchemaVer key in the settings table as our first check
  # It should always be present
  def test_get_setting
    schema_version = @db.get_setting('DBSchemaVer')
    assert schema_version.to_i > 0
  end

  # Check the DBSchemaVer, once queried, is in the setting cache
  def test_get_setting_cache
    schema_version = @db.get_setting('DBSchemaVer')
    assert @db.setting_cache['DBSchemaVer_'].to_i > 0
  end

  def test_list_channels
    channels = @db.list_channels
    
    assert_kind_of Array, channels 
    assert channels.length > 0
    assert_kind_of MythTV::Channel, channels[0] 
    assert channels[0].chanid > 0
  end
  
  # Test we can pull back a single channel when
  # specifying a :chanid
  def test_list_single_chanid
    first_channel_list = @db.list_channels
    wanted_chanid = first_channel_list[0].chanid

    second_channel_list = @db.list_channels(:chanid => wanted_chanid)
    assert_equal 1, second_channel_list.length

    channel = second_channel_list[0]
    assert_kind_of MythTV::Channel, channel
    assert_equal channel.chanid, wanted_chanid
  end
  
  def test_list_multiple_chanids
    first_channel_list = @db.list_channels
    first_five = first_channel_list.slice(0..4)
    wanted_chanids = first_five.map { |x| x.chanid }

    second_channel_list = @db.list_channels(:chanid => wanted_chanids)
    assert_equal 5, second_channel_list.length
    second_channel_list
  end
  
  def test_list_programs
    programs = @db.list_programs(:limit => 10)
    
    assert_equal 10, programs.length
  end
  
  def test_list_programs_with_search
    programs = @db.list_programs(:conditions => ['title LIKE ?', "%"],
                                 :limit => 5)
    assert programs.length > 0
  end
  
  def test_list_programs_with_starttime_range
    # Programs in the next two hours
    programs = @db.list_programs(:conditions => ['starttime BETWEEN ? AND ?', Time.now, Time.now + 7200],
                                 :limit => 1)
    
    assert_equal 1, programs.length
  end
  
  def test_program_links_to_channel
    programs = @db.list_programs(:conditions => ['title LIKE ?', "%"], :limit => 1)
    program_channel = programs[0].channel
    assert_kind_of MythTV::Channel, program_channel
  end

  def test_new_schedule
    # Get list of schedules for later reference
    num_schedules = @db.list_recording_schedules
    programs = @db.list_programs(:conditions => ['starttime BETWEEN ? AND ?', Time.now + 3600, Time.now + 7200],
                                 :limit => 1)
    
    # Convert our first program selected into a recording schedule
    new_schedule = MythTV::RecordingSchedule.new(programs[0], @db)
    new_schedule.save
    
    # Get new list
    new_num_schedules = @db.list_recording_schedules
    # Assert that we now have one more schedule
    assert_equal num_schedules.length + 1, new_num_schedules.length
    
    assert new_schedule.recordid > 0
    
    destroy_result = new_schedule.destroy()
    assert destroy_result
  end
  
  def test_new_and_modify_schedule
    # Get list of schedules for later reference
    num_schedules = @db.list_recording_schedules
    programs = @db.list_programs(:conditions => ['starttime BETWEEN ? AND ?', Time.now + 3600, Time.now + 7200],
                                 :limit => 1)
    
    # Convert our first program selected into a recording schedule
    new_schedule = MythTV::RecordingSchedule.new(programs[0], @db)
    new_schedule.save
    
    new_schedule.type = 4
    new_schedule.save

    test_query = @db.list_recording_schedules(:conditions => ['recordid = ?', new_schedule.recordid])
    assert_equal 1, test_query.length
    
    test_retrieval = test_query[0]
    
    assert_equal 4, test_retrieval.type

    destroy_result = new_schedule.destroy()
    assert destroy_result
  end
  
end

