# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "betfair/version"

Gem::Specification.new do |s|
  s.name        = "betfair"
  s.version     = Betfair::VERSION
  s.authors     = ["Luke Byrne"]
  s.email       = ["lukeb@lukebyrne.com"]
  s.homepage    = "https://github.com/lukebyrne/betfair"
  s.summary     = %q{Betfair API gem.}
  s.description = %q{Gem for accessing the Betfair API.}

  s.rubyforge_project = "betfair"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'savon', "<= 0.8.6"
  
  s.add_development_dependency  'rake'
  s.add_development_dependency  'rspec'
  s.add_development_dependency  'savon_spec', "= 0.1.5"
  s.add_development_dependency  'mocha', '= 0.10.4'
end
