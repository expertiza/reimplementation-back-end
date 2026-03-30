# frozen_string_literal: true

ENV['COVERAGE_STARTED'] = 'true'

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/test/'
  use_merging true
  merge_timeout 3600
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  parallelize(workers: 1)  # ← temporarily force single process
  fixtures :all

  parallelize_teardown do |worker|
    SimpleCov.result
  end
end