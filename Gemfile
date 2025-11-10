source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.7'

gem 'mysql2', '~> 0.5.7'
gem 'sqlite3', '~> 1.4'  # Alternative for development
gem 'puma', '~> 6.0'
gem 'rails', '~> 8.0', '>= 8.0.1'
gem 'mini_portile2', '~> 2.8'  # Helps with native gem compilation
gem 'observer'  # Required for Ruby 3.4.5 compatibility with Rails 8.0
gem 'mutex_m'  # Required for Ruby 3.4.5 compatibility
gem 'faraday-retry'  # Required for Faraday v2.0+ compatibility
gem 'bigdecimal'  # Required for Ruby 3.4.5 compatibility
gem 'csv'  # Required for Ruby 3.4.5 compatibility
gem 'date'  # Required for Ruby 3.4.5 compatibility
gem 'delegate'  # Required for Ruby 3.4.5 compatibility
gem 'forwardable'  # Required for Ruby 3.4.5 compatibility
gem 'logger'  # Required for Ruby 3.4.5 compatibility
gem 'monitor'  # Required for Ruby 3.4.5 compatibility
gem 'ostruct'  # Required for Ruby 3.4.5 compatibility
gem 'set'  # Required for Ruby 3.4.5 compatibility
gem 'singleton'  # Required for Ruby 3.4.5 compatibility
gem 'timeout'  # Required for Ruby 3.4.5 compatibility
gem 'uri'  # Required for Ruby 3.4.5 compatibility
gem 'rswag-api'
gem 'rswag-ui'
gem 'active_model_serializers', '~> 0.10.0'
gem 'psych', '~> 5.2'  # Ensure compatible psych version for Ruby 3.4.5

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

gem 'jwt', '~> 2.7', '>= 2.7.1'
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.18.4', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

gem 'lingua'

# This is a really small gem that can be used to retrieve objects from the database in the order of the list given
gem 'find_with_order'


group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'database_cleaner-active_record'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rubocop'
  gem 'simplecov', require: false, group: :test
  gem 'coveralls'
  gem 'simplecov_json_formatter'
  gem 'shoulda-matchers'
  gem 'danger'
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem 'spring'
end
