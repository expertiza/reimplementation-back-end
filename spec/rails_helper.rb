# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

require 'factory_bot_rails'
require 'database_cleaner/active_record'

# Override DATABASE_URL for tests to prevent remote DB errors
if Rails.env.test?
 ENV['DATABASE_URL'] = 'mysql2://root:expertiza@127.0.0.1/reimplementation_test'
end

# Load support files BEFORE RSpec.configure so helpers are available
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include RolesHelper
  config.before(:suite) do
    FactoryBot.factories.clear
    FactoryBot.find_definitions
    # Allow DatabaseCleaner to run even if DATABASE_URL is set
    DatabaseCleaner.allow_remote_database_url = true

    # Use `deletion` in GitHub Actions to prevent foreign key issues
    if ENV['GITHUB_ACTIONS']
      DatabaseCleaner.clean_with(:deletion, except: %w[ar_internal_metadata])
    else
      DatabaseCleaner.clean_with(:truncation)
    end
  end
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Ensures proper cleanup
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  if config.respond_to?(:fixture_paths=)
    config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]
  else
    config.fixture_path = Rails.root.join('spec/fixtures')
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end