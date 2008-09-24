Gem::Specification.new do |s|
  s.name = 'ruby-mythtv'
  s.version = '0.1.2'
 
  s.specification_version = 2 if s.respond_to? :specification_version=
 
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.date = %q{2008-09-24}
  s.description = %q{Ruby implementation of the MythTV communication protocol}
  s.authors = [ 'Nick Ludlam' ]
  s.email = %q{nick@recoil.org}
  s.extra_rdoc_files = [ 'History.txt', 'License.txt', 'README.txt' ]
  s.files = [ 'History.txt', 'License.txt', 'README.txt', 'Rakefile',
              'lib/ruby-mythtv.rb', 'mythtv/backend.rb', 'mythtv/channel.rb',
              'mythtv/database.rb', 'mythtv/program.rb', 'mythtv/protocol.rb',
              'mythtv/recording.rb', 'mythtv/recording_schedule.rb',
              'mythtv/utils.rb', 'test/test_backend.rb', 'test/test_db.rb',
              'test/test_helper.rb', 'test_stream.rb', 'Todo.txt' ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/nickludlam/ruby-mythtv/}
  s.rdoc_options = ['--main', 'README.txt']
  s.require_paths = ['lib']
  s.rubyforge_project = %q{ruby-mythtv}
  s.rubygems_version = %q{0.1.2}
  s.add_dependency('mysql')
  s.summary = %q{Ruby implementation of the MythTV backend protocol}
  s.test_files = [ 'test/test_helper.rb', 'test/test_backend.rb', 'test/test_db.rb' ]
end
