require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name = %q{ruby-mythtv}
  s.version = "0.2.0"
 
  s.specification_version = 2 if s.respond_to? :specification_version=
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Ludlam"]
  s.date = %q{2008-07-27}
  s.description = %q{Ruby implementation of the MythTV communication protocol}
  s.email = %q{nick@recoil.org}
  s.extra_rdoc_files = ["History.txt", "License.txt", "README.txt"]
  s.files = ["History.txt", "License.txt", "README.txt", "Rakefile", "lib/ruby-mythtv.rb", "lib/mythtv/backend.rb", "lib/mythtv/channel.rb", "lib/mythtv/database.rb", "lib/mythtv/program.rb", "lib/mythtv/protocol.rb", "lib/mythtv/recording.rb", "lib/mythtv/recording_schedule.rb", "lib/mythtv/utils.rb", "test/test_backend.rb", "test/test_db.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/nickludlam/ruby-mythtv/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ruby-mythtv}
  s.rubygems_version = %q{0.2.0}
  s.summary = %q{Ruby implementation of the MythTV backend protocol}
  s.test_files = ["test/test_backend.rb", "test/test_helper.rb"]
end

Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 

task :build => "pkg/#{spec.name}-#{spec.version}.gem" do
  puts "Generated latest version"
end

desc "Run basic unit tests"
Rake::TestTask.new("test_units") do |t|
  t.pattern = ENV["TESTFILES"] || ['test/test_backend.rb', 'test/test_db.rb']
  t.verbose = true
  t.warning = true
end

task :test => :test_units

Rake::TestTask.new('test_db') do |t|
  t.pattern = ['test/test_db.rb']
  t.verbose = true
end
  
desc "Run unit tests as default"
task :default => :test_units
