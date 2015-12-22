require File.join(File.dirname(__FILE__), 'lib', 'tilia', 'xml', 'version')
Gem::Specification.new do |s|
  s.name        = 'tilia-xml'
  s.version     = Tilia::Xml::Version::VERSION
  s.licenses    = ['BSD-3-Clause']
  s.summary     = 'Port of the sabre-xml library to ruby.'
  s.description = "Port of the sabre-xml library to ruby.\n\nThe Tilia XML parser is the only XML library that you may not hate."
  s.author      = 'Jakob Sack'
  s.email       = 'tilia@jakobsack.de'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/tilia/tilia-xml'
  s.add_runtime_dependency 'activesupport', '~> 4.2'
  s.add_runtime_dependency 'libxml-ruby', '~> 2.8'
  s.add_runtime_dependency 'tilia-uri', '~> 1.0'
end
