# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'logger'
require 'bundler/setup' # Set up gems listed in the Gemfile.
unless ENV['RAILS_ENV'] == 'test'
  require 'bootsnap/setup'
end
 # Speed up boot time by caching expensive operations.
