# Add these lines at the very top, before any other requires
require 'simplecov'
require 'coveralls'

# Define a custom formatter to ensure the json is properly saved
class SimpleCovJson < SimpleCov::Formatter
  def format(result)
    data = {}
    data[:timestamp] = Time.now.to_i
    data[:command_name] = SimpleCov.command_name
    data[:metrics] = {
      covered_percent: result.covered_percent,
      covered_lines: result.covered_lines.count,
      total_lines: result.total_lines
    }
    data[:files] = result.files.map do |file|
      {
        name: file.filename,
        covered_percent: file.covered_percent,
        covered_lines: file.covered_lines.count,
        total_lines: file.total_lines,
        line_counts: {
          total: file.total_lines,
          covered: file.covered_lines.count,
          missed: file.missed_lines.count
        }
      }
    end

    # Ensure the coverage directory exists
    FileUtils.mkdir_p('coverage')
    
    # Write standard resultset.json that CodeClimate expects
    File.open(File.join(SimpleCov.coverage_dir, '.resultset.json'), 'w+') do |f|
      f.write(JSON.pretty_generate({
        "RSpec" => {
          "coverage" => result.original_result,
          "timestamp" => Time.now.to_i
        }
      }))
    end
    
    # Also write a coverage.json file as a backup
    File.open(File.join(SimpleCov.coverage_dir, 'coverage.json'), 'w+') do |f|
      f.write(JSON.pretty_generate(data))
    end
  end
end

# Use multiple formatters including our custom JSON formatter
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
  SimpleCovJson.new
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
  
  # Enable branch coverage
  enable_coverage :branch
  
  # For debugging: print all tracked files
  at_exit do
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
  end
end

ENV['RAILS_ENV'] ||= 'test'

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

require 'factory_bot_rails'
require 'database_cleaner/active_record'

# Override DATABASE_URL for tests to prevent remote DB errors
if Rails.env.test?
  ENV['DATABASE_URL'] = 'mysql2://root:expertiza@127.0.0.1/reimplementation_test'
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
  config.fixture_path = Rails.root.join('spec/fixtures')

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

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
