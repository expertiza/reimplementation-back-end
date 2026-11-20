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
 ENV['DATABASE_URL'] = 'mysql2://root:expertiza@db:3306/reimplementation_test'
end

# frozen_string_literal: true

# Tracks which spec file is currently running so rails_helper can detect
# file boundaries (each example is a fresh object, so a plain instance
# variable would not survive between examples).
module RSpecFileIsolation
  class << self
    attr_writer :current_file

    def current_file
      @current_file
    end
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
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

    # The suite-start clean above removes the legacy reference/lookup rows
    # (deadline_types, deadline_rights) that specs reference by their fixed
    # legacy ids; seed them back before any example runs. (The file-boundary
    # hook below re-seeds after each wipe as well.)
    SpecReferenceData.seed! if defined?(SpecReferenceData)
  end
  # Runs before every example group's own before(:all) hooks (hooks run in
  # registration order and rails_helper loads first), so it detects file
  # boundaries before the file's own setup commits anything.
  config.before(:all) do |example_group|
    file = example_group.class.metadata[:file_path]
    next if RSpecFileIsolation.current_file == file

    RSpecFileIsolation.current_file = file
    # Data committed by the previous file (most specs set up shared records
    # in before(:all), which runs outside the per-test transaction and
    # therefore survives its rollback) would otherwise leak into this file
    # and break its assumptions about ids, names and emptiness. Wipe it on
    # a separate connection so the removal is not part of - and cannot be
    # undone by - this test's transaction.
    connection = if ActiveRecord::Base.connection_pool.respond_to?(:checkout_with_new_connection)
                   ActiveRecord::Base.connection_pool.checkout_with_new_connection
                 else
                   ActiveRecord::Base.connection_pool.new_connection
                 end
    begin
      connection.execute('SET FOREIGN_KEY_CHECKS = 0')
      connection.tables.each do |table|
        next if %w[ar_internal_metadata schema_migrations].include?(table)

        connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
      end
      connection.tables.each do |table|
        next if %w[ar_internal_metadata schema_migrations].include?(table)

        connection.execute("ALTER TABLE #{connection.quote_table_name(table)} AUTO_INCREMENT = 1")
      end
      connection.execute('SET FOREIGN_KEY_CHECKS = 1')
    ensure
      connection.disconnect! if connection.connected?
    end
    # The wipe above also removed the reference rows, so restore them.
    SpecReferenceData.seed! if defined?(SpecReferenceData)
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

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = Rails.root.join('spec/fixtures')
  if config.respond_to?(:fixture_paths=)
    config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]
  else
    # fallback for older Rails / rspec-rails
    config.fixture_path = Rails.root.join('spec/fixtures')
  end
  # Since we're using Factory Bot instead of fixtures, we don't need fixture_path
  # config.fixture_path is deprecated in newer RSpec versions anyway

  # We're using DatabaseCleaner instead of transactional fixtures
  # config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
