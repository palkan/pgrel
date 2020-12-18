source 'https://rubygems.org'

gemspec

gem "pry-byebug", platform: :mri

eval_gemfile "gemfiles/rubocop.gemfile"

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'activerecord', '~> 6.1'
end
