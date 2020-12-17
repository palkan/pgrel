# frozen_string_literal: true

# Maintain your gem's version:
require_relative "lib/pgrel/version"

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

  s.files         = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activerecord", ">= 4.0"

  s.add_development_dependency "pg", ">= 0.18"
  s.add_development_dependency 'rake', '>= 10.1'
  s.add_development_dependency "rspec", ">= 3.1"
end
