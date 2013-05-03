Gem::Specification.new do |s|
  s.name         = "sarah"
  s.version      = "0.0.1"
  s.authors      = ["Brian Katzung"]
  s.email        = ["briank@kappacs.com"]
  s.homepage     = "http://www.kappacs.com"
  s.summary      = "Sequential array/random-access hash"
  s.description  = "Implements a hybrid data structure composed of a sequential array and random-access hash"
  s.license      = "MIT"
 
  s.files        = Dir.glob("lib/**/*") + %w{sarah.gemspec}
  s.test_files   = Dir.glob("test/**/*")
  s.require_path = 'lib'
end
