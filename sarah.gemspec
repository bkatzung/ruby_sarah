Gem::Specification.new do |s|
  s.name         = "sarah"
  s.version      = "3.0.0"
  s.date         = "2014-04-26"
  s.authors      = ["Brian Katzung"]
  s.email        = ["briank@kappacs.com"]
  s.homepage     = "http://rubygems.org/gems/sarah"
  s.summary      = "Sequential array/random-access hash"
  s.description  = "Implements a hybrid data structure composed of a sequential array and random-access hash"
  s.license      = "MIT"
 
  s.files        = Dir.glob("lib/**/*") +
		   %w{sarah.gemspec HISTORY.txt .yardopts}
  s.test_files   = Dir.glob("test/**/*.rb")
  s.require_path = 'lib'
end
