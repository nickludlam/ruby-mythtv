Gem::Specification.new do |s|
  s.name = %q{ruby-mythtv}
  s.version = "0.1.0"
 
  s.specification_version = 2 if s.respond_to? :specification_version=
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Ludlam"]
  s.date = %q{2008-06-08}
  s.description = %q{Ruby implementation of the MythTV communication protocol}
  s.email = %q{nick@recoil.org}
  s.extra_rdoc_files = ["History.txt", "License.txt", "README.txt"]
  s.files = ["History.txt", "License.txt", "README.txt", "Rakefile", "lib/ruby-mythtv.rb", "lib/mythtv/backend.rb", "lib/mythtv/recording.rb", "test/test_backend.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/nickludlam/ruby-mythtv/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ruby-mythtv}
  s.rubygems_version = %q{0.1.0}
  s.summary = %q{Ruby implementation of the MythTV backend protocol}
  s.test_files = ["test/test_backend.rb", "test/test_helper.rb"]
end