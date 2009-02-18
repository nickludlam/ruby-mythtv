require File.dirname(__FILE__) + '/test_helper.rb'

class TestDatabase < Test::Unit::TestCase
  def setup
    abort("\n\tERROR: You must set the environment variable MYTHTV_HOST to the name of your MythTV database server\n\n") unless ENV['MYTHTV_HOST']
    abort("\n\tERROR: You must set the environment variable MYTHTV_PW to your MySQL MythTV password\n\n") unless ENV['MYTHTV_PW']
    
    conn_opts = Hash.new(:log_level => Logger::DEBUG)
    conn_opts[:host] = ENV['MYTHTV_HOST'] if ENV.has_key?('MYTHTV_HOST')
    conn_opts[:database_user] = ENV['MYTHTV_USER'] if ENV.has_key?('MYTHTV_USER')
    conn_opts[:database_password] = ENV['MYTHTV_PW'] if ENV.has_key?('MYTHTV_PW')
    
    @db = MythTV::Database.new(conn_opts)
  end
  
  def teardown
    #@db.disconnect
  end
  
  # Check the DBSchemaVer key in the settings table as our first check
  # It should always be present
  def test_get_setting
    schema_version = MythTV::Setting.data_for_value('DBSchemaVer')
    assert schema_version.to_i > 0
  end

  def test_list_channels
    channels = MythTV::Channel.find(:all)
    
    assert_kind_of Array, channels
    assert channels.length > 0
    assert_kind_of MythTV::Channel, channels[0]
    assert channels[0].chanid > 0
  end
  
  # Test we can pull back a single channel when
  # specifying a :chanid
  def test_list_single_chanid
    channel_list = MythTV::Channel.find(:all)
    wanted_chanid = channel_list[0].chanid

    channel = MythTV::Channel.find_by_chanid(wanted_chanid)

    assert_kind_of MythTV::Channel, channel
    assert_equal channel.chanid, wanted_chanid
  end
  
  def test_list_programs
    programs = MythTV::Program.find(:all, :limit => 10)
    
    assert_equal 10, programs.length
  end
  
  def test_list_programs_with_search
    programs = MythTV::Program.find(:all, :conditions => ['title like ?', '%'], :limit => 5)
    assert_equal 5, programs.length
  end
  
  def test_list_programs_with_starttime_range
    # Programs in the next two hours. Assume database is up to date
    programs = MythTV::Program.find(:all, :conditions => ['starttime BETWEEN ? AND ?', Time.now, Time.now + 7200],
                                          :limit => 1)
    
    assert_equal 1, programs.length
  end
  
  def test_program_links_to_channel
    programs = MythTV::Program.find(:all, :limit => 1)
    assert_kind_of MythTV::Channel, programs[0].channel
  end

  def test_new_schedule
    # Get list of schedules for later reference
    num_schedules = MythTV::RecordingSchedule.count
    program = MythTV::Program.find(:first, :conditions => ['starttime BETWEEN ? AND ?', Time.now, Time.now + 7200],
                                           :limit => 1)

    # Check we have one at all
    assert program
    
    # Convert our first program selected into a recording schedule
    new_schedule = MythTV::RecordingSchedule.new(program)
    new_schedule.save
    
    # Get new list
    new_num_schedules = MythTV::RecordingSchedule.count
    # Assert that we now have one more schedule
    assert_equal num_schedules + 1, new_num_schedules
    
    assert new_schedule.recordid.to_i > 0
    
    destroy_result = new_schedule.destroy()
    assert destroy_result
  end
  
  def test_new_and_modify_schedule
    # Get list of schedules for later reference
    num_schedules = MythTV::RecordingSchedule.count
    program = MythTV::Program.find(:first, :conditions => ['starttime BETWEEN ? AND ?', Time.now, Time.now + 7200],
                                           :limit => 1)
    
    # Check we have one at all
    assert program

    # Convert our first program selected into a recording schedule, and save it
    new_schedule = MythTV::RecordingSchedule.new(program)
    new_schedule.save
    
    new_schedule.type = 4
    new_schedule.save

    # We should find this now with new query
    test_query = MythTV::RecordingSchedule.find(:all, :conditions => ['recordid = ?', new_schedule.recordid])
    assert_equal 1, test_query.length
    
    test_retrieval = test_query[0]
    
    assert_equal 4, test_retrieval.type

    destroy_result = new_schedule.destroy()
    assert destroy_result
  end
  
end

