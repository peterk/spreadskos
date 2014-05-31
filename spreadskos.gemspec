# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

#
Gem::Specification.new do |s|
  s.name        = 'spreadskos'
  s.version     = '0.0.5'
  s.date        = '2013-07-11'
  s.summary     = "Spreadskos"
  s.description = "Convert vocabularies created in a spreadsheet template to SKOS."
  s.authors     = ["Peter Krantz"]
  s.email       = 'peter@peterkrantz.se'
  s.files       = ["lib/skos.rdf", "lib/spreadskos.rb"]
  s.homepage    =
    'http://rubygems.org/gems/spreadskos'

  s.add_dependency('rdf-rdfxml', '~> 1.0.2') # to make sure the fix for missing language attrobites is included
  s.add_dependency('linkeddata', '~> 1.0.5')
  s.add_dependency('builder')
  s.add_dependency('logger')
  s.add_dependency('roo')

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

end
