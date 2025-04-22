# Start with environment and database URL configuration
ENV['RAILS_ENV'] ||= 'test'

# Override DATABASE_URL for tests to match CI configuration
if ENV['RAILS_ENV'] == 'test'
  # Use the environment variable if already set (by CI), otherwise use local default
  ENV['DATABASE_URL'] ||= 'mysql2://root:expertiza@127.0.0.1:3306/expertiza_test'
end

# Require spec_helper first - it has minimal dependencies
require 'spec_helper'

# Then set up code coverage (before Rails loads)
require 'simplecov'
require 'coveralls'
require 'simplecov_json_formatter'  # Add this line to require the JSON formatter

# Set up formatters for SimpleCov
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,  # Use the built-in JSON formatter
  Coveralls::SimpleCov::Formatter
])

# Set a consistent coverage directory
SimpleCov.coverage_dir 'coverage'

# Start SimpleCov with a consistent configuration
SimpleCov.start 'rails' do
  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Services", "app/services"
  add_group "Helpers", "app/helpers"
  
  # Track all Ruby files in these directories
  track_files "{app,lib,config}/**/*.rb"
  
  # Clear any default filters and add our own
  filters.clear
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

# Now load Rails environment after SimpleCov setup
begin
  require_relative '../config/environment'
rescue => e
  puts "Error loading Rails environment: #{e.message}"
  puts e.backtrace.join("\n")
  raise
end

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Add additional testing libraries
require 'factory_bot_rails'
require 'database_cleaner/active_record'

# RSpec configuration
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  
  # Database cleaner setup
  config.before(:suite) do
    FactoryBot.factories.clear
    FactoryBot.find_definitions
    
    # Explicitly check that the database is accessible with retry mechanism
    retry_count = 0
    max_retries = 5
    begin
      ActiveRecord::Base.connection
      puts "✅ Database connection successful"
    rescue => e
      retry_count += 1
      if retry_count <= max_retries
        puts "❌ Database connection failed (attempt #{retry_count}/#{max_retries}): #{e.message}"
        puts "Waiting 3 seconds before retry..."
        sleep 3
        retry
      else
        puts "❌ Database connection failed after #{max_retries} attempts: #{e.message}"
        abort("Database connection error. Please check database configuration.")
      end
    end
    
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

  # Rest of your RSpec configuration remains unchanged
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# Debugging at end of file to ensure all imports worked
at_exit do
  # SimpleCov debug information
  if defined?(SimpleCov) && SimpleCov.result
    puts "\nSimpleCov tracked files:"
    SimpleCov.result.files.each do |file|
      puts "- #{file.filename} (#{file.covered_percent.round(2)}%)"
    end
    
    # Debug the location of coverage files
    puts "\nCoverage files location:"
    puts "Coverage dir: #{SimpleCov.coverage_dir}"
    resultset_path = File.join(SimpleCov.coverage_dir, '.resultset.json')
    coverage_path = File.join(SimpleCov.coverage_dir, 'coverage.json')
    puts "Resultset exists: #{File.exist?(resultset_path)}"
    puts "Coverage exists: #{File.exist?(coverage_path)}"
  else
    puts "⚠️ SimpleCov result not available"
  end
end
