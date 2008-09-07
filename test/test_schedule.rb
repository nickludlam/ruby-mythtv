require File.dirname(__FILE__) + '/test_helper.rb'

class TestSchedule < Test::Unit::TestCase
  def setup
    @raw_schedule = File.read("test/test_schedule.xml")
  end
  
  # Assuming the system is up for more than 0 seconds!
  def test_parse
    MythTV::Backend.process_guide_xml(@raw_schedule)
  end
  
  def test_live
  end
  
end