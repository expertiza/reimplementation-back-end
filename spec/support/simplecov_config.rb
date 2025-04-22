require 'simplecov'

# Configure SimpleCov
SimpleCov.start 'rails' do
  # Add coverage groups
  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Services", "app/services"
  add_group "Helpers", "app/helpers"
  
  # Set minimum coverage if needed
  # minimum_coverage 90
  
  # Set the output directory
  coverage_dir 'coverage/simplecov'
end

puts "SimpleCov configured - report will be in coverage/simplecov/index.html"