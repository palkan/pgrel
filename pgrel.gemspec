$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pgrel/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pgrel"
  s.version     = Pgrel::VERSION
  s.authors     = ["palkan"]
  s.email       = ["dementiev.vm@gmail.com"]
  s.homepage    = "http://github.com/palkan/pgrel"
  s.summary     = "ActiveRecord extension for querying hstore and jsonb."
  s.description = "ActiveRecord extension for querying hstore and jsonb."
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activerecord", ">=4.0.0"

  s.add_development_dependency "pg", "~>0.18"

  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency "rspec", "~> 3.1.0"
end
