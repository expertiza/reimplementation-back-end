source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.7'

gem 'mysql2', '~> 0.5.5'
gem 'puma', '~> 5.0'
gem 'rails', '~> 8.0', '>= 8.0.1'
gem 'rswag-api'
gem 'rswag-ui'

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
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem 'spring'
end
