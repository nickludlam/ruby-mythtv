require '../lib/ruby-mythtv'

@backend = MythTV::Backend.new(:host => 'pico')

all_recordings = @backend.query_recordings

@backend.stream(all_recordings[-1]) do |chunk|
  puts chunk
end
