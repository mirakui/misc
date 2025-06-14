require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler/setup'
require 'webmock/rspec'
require 'vcr'

# Require all library files
Dir[File.join(__dir__, '..', 'lib', '**', '*.rb')].each { |f| require f }

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<ANNICT_ACCESS_TOKEN>') { ENV['ANNICT_ACCESS_TOKEN'] }
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Allow stubbing of ENV variables
  config.before(:each) do
    allow(ENV).to receive(:[]).and_call_original
  end
end