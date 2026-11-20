# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
# Load the real simplecov gem before minitest's simplecov plugin runs.
# simplecov_json_formatter (auto-required at boot) opens a bare top-level
# SimpleCov module, which otherwise makes the plugin crash with
# "undefined method 'external_at_exit=' for module SimpleCov".
require 'simplecov'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
