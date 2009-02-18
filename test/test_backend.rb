require File.dirname(__FILE__) + '/test_helper.rb'

class TestBackend < Test::Unit::TestCase
  def setup
    abort("\n\tERROR: You must set the environment variable MYTHTV_HOST to the name of your MythTV backend server\n\n") unless ENV['MYTHTV_HOST']
    @backend = MythTV.connect_backend(:host => ENV['MYTHTV_HOST'])
  end
  
  def teardown
    @backend.close
  end
  
  # Assuming the system is up for more than 0 seconds!
  def test_connection
    uptime = @backend.query_uptime
    assert uptime > 0
  end
  
  # Assuming there is at least one recording on the test server
  def test_get_recordings
    recordings = @backend.query_recordings
    assert recordings.length > 0
    assert_kind_of MythTV::Recording, recordings[0]
  end

  # Assuming there is at least one scheduled recording on the test server
  def test_get_scheduled
    scheduled = @backend.query_scheduled
    assert scheduled.length > 0
    assert_kind_of MythTV::Recording, scheduled[0]
  end
  
  # Test the generation of a preview image
  def test_make_preview_image
    recordings = @backend.query_recordings
    
    recording = recordings[0]
    test_image = @backend.preview_image(recording, :secs_in => 1)
    assert test_image.length > 0
    
    # Define an array of the decimal values of the PNG magic number
    png_sig = [137, 80, 78, 71, 13, 10, 26, 10]
    test_image_sig = (0..7).collect { |i| test_image[i] }
    
    assert_equal test_image_sig, png_sig
  end
  
  # In this test, we ignore the @backend instance connection which was created by setup()
  # and perform our own block of commands on a new connection
  def test_perform_commands
    MythTV::Backend.perform_commands(:host => ENV['MYTHTV_HOST']) do |connection|
      # Check the query_uptime method and query_memstats methods
      uptime = connection.query_uptime
      assert uptime > 0
      
      memstats = connection.query_memstats
      assert_equal Hash, memstats.class
      assert_equal 4, memstats.keys.length
    end
  end
  
  # def test_process_guide_xml
  #   guide_data = @backend.get_program_guide
  #   
  #   channels = MythTV::Backend.process_guide_xml(guide_data)
  # end
  
  # Don't run this by default as it takes a while. Possibly limit to 100kB?
  #def test_download
  #  recordings = @backend.query_recordings
  #  
  #  recording = recordings[-2]
  #  @backend.download(recording)
  #end
  
  
end
