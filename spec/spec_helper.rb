# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end

require "rspec"
require "active_record"
require "pg"
require "pgrel"

connection_params =
  if ENV.key?("DATABASE_URL")
    {"url" => ENV["DATABASE_URL"]}
  else
    {
      "host" => ENV["DB_HOST"] || "localhost",
      "username" => ENV["DB_USER"]
    }
  end

ActiveRecord::Base.establish_connection(
  {
    "adapter" => "postgresql",
    "database" => "pgrel_test"
  }.merge(connection_params)
)

connection = ActiveRecord::Base.connection

unless connection.extension_enabled?("hstore")
  connection.enable_extension "hstore"
  connection.commit_db_transaction
end

connection.reconnect!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) { User.delete_all }
end
