#!/usr/bin/env ruby
# filepath: scripts/show_coverage.rb
require 'json'

# Find the resultset.json file
resultset_file = './coverage/.resultset.json'
unless File.exist?(resultset_file)
  puts "Could not find #{resultset_file}"
  exit 1
end

# Parse the JSON data
begin
  data = JSON.parse(File.read(resultset_file))
  coverage_data = data["RSpec"]["coverage"]
rescue => e
  puts "Error parsing coverage data: #{e.message}"
  exit 1
end

# Debug the structure of the coverage data
puts "Coverage data structure:"
first_file = coverage_data.keys.first
puts "First file: #{first_file}"
puts "Data structure: #{coverage_data[first_file].class}"
puts "Lines data structure: #{coverage_data[first_file]['lines'].class}" if coverage_data[first_file].is_a?(Hash) && coverage_data[first_file]['lines']
puts "\n"

# Function to calculate coverage percentage - handles both array and hash formats
def calculate_coverage(lines_data)
  # Handle different data structures
  if lines_data.is_a?(Hash) && lines_data['lines']
    lines = lines_data['lines']
  elsif lines_data.is_a?(Hash)
    lines = lines_data
  else
    lines = lines_data # assume it's already the lines array
  end

  covered = 0
  total = 0
  
  if lines.is_a?(Hash)
    # Handle format where lines are {line_number => execution_count}
    lines.each do |line_num, count|
      next if count.nil?  # Skip lines that are not relevant (comments, etc.)
      total += 1
      covered += 1 if count.to_i > 0
    end
  elsif lines.is_a?(Array)
    # Handle format where lines are [count, count, nil, count, ...]
    lines.each_with_index do |count, idx|
      next if count.nil?  # Skip lines that are not relevant (comments, etc.)
      total += 1
      covered += 1 if count.to_i > 0
    end
  end
  
  return 0 if total == 0
  (covered.to_f / total * 100).round(2)
end

# Function to get missed lines - handles both array and hash formats
def get_missed_lines(lines_data)
  # Handle different data structures
  if lines_data.is_a?(Hash) && lines_data['lines']
    lines = lines_data['lines']
  elsif lines_data.is_a?(Hash)
    lines = lines_data
  else
    lines = lines_data # assume it's already the lines array
  end

  if lines.is_a?(Hash)
    # Handle format where lines are {line_number => execution_count}
    return lines.select { |line_num, count| count == 0 }.keys.map(&:to_i).sort
  elsif lines.is_a?(Array)
    # Handle format where lines are [count, count, nil, count, ...]
    missed = []
    lines.each_with_index do |count, idx|
      missed << (idx + 1) if count == 0
    end
    return missed
  end
  []
end

# Print coverage data for student_review files specifically
puts "\n=== Student Review Files Coverage ===\n\n"

student_review_files = coverage_data.keys.select { |k| k =~ /student_review/ }

if student_review_files.empty?
  puts "No student_review files found in coverage data."
  puts "Available files:"
  coverage_data.keys.each do |file|
    puts "  - #{file}"
  end
  puts "\n"
else
  student_review_files.each do |file|
    file_data = coverage_data[file]
    
    # Handle different formats
    if file_data.is_a?(Hash) && file_data['lines']
      lines = file_data['lines']
    else
      lines = file_data # assume it's already the lines array/hash
    end
    
    percentage = calculate_coverage(lines)
    missed = get_missed_lines(lines)
    
    puts "#{file}:"
    puts "  Coverage: #{percentage}%"
    
    if lines.is_a?(Hash)
      total_lines = lines.values.compact.size
    else
      total_lines = lines.compact.size
    end
    
    puts "  Total Lines: #{total_lines}"
    puts "  Covered Lines: #{total_lines - missed.size}"
    puts "  Missed Lines: #{missed.size}"
    
    # Show up to 10 missed line numbers
    if missed.any?
      limited_missed = missed.take(10)
      puts "  Missed Line Numbers: #{limited_missed.join(', ')}#{missed.size > 10 ? '...' : ''}"
    end
    puts
    
    # Show code with coverage
    puts "Code Coverage Details:"
    puts "---------------------"
    if File.exist?(file)
      File.readlines(file).each_with_index do |line, idx|
        line_num = idx + 1
        
        if lines.is_a?(Hash)
          count = lines[line_num.to_s]
        else
          count = lines[idx] if idx < lines.size
        end
        
        if count.nil?
          marker = ' '  # Not executable code
        elsif count == 0
          marker = '✘'  # Not covered
        else
          marker = '✓'  # Covered
        end
        
        puts "#{line_num.to_s.rjust(3)} #{marker} #{line.chomp}"
      end
    else
      puts "  [Source file not found]"
    end
    puts "\n\n"
  end
end

# If no student_review files were found, let's show at least some useful files
if student_review_files.empty?
  puts "Showing coverage for files with 'review' in name instead:"
  review_files = coverage_data.keys.select { |k| k =~ /review/ }
  
  if review_files.empty?
    puts "No files with 'review' in their name found."
    puts "Showing service files instead:"
    service_files = coverage_data.keys.select { |k| k =~ /service/ }
    
    if service_files.empty?
      puts "No service files found. Showing controller files:"
      controller_files = coverage_data.keys.select { |k| k =~ /controller/ }
      review_files = controller_files.take(2) # Just show a couple as examples
    else
      review_files = service_files
    end
  end
  
  review_files.each do |file|
    file_data = coverage_data[file]
    
    # Handle different formats
    if file_data.is_a?(Hash) && file_data['lines']
      lines = file_data['lines']
    else
      lines = file_data # assume it's already the lines array/hash
    end
    
    percentage = calculate_coverage(lines)
    
    puts "#{file}:"
    puts "  Coverage: #{percentage}%"
    puts
  end
end

# Print overall statistics
total_lines = 0
covered_lines = 0

coverage_data.each do |file, data|
  next unless file =~ /\.rb$/  # Only count Ruby files
  
  # Handle different formats
  if data.is_a?(Hash) && data['lines']
    lines = data['lines']
  else
    lines = data # assume it's already the lines array/hash
  end
  
  missed = get_missed_lines(lines)
  
  if lines.is_a?(Hash)
    file_lines = lines.values.compact.size
  else
    file_lines = lines.compact.size
  end
  
  file_covered = file_lines - missed.size
  
  total_lines += file_lines
  covered_lines += file_covered
end

overall_percentage = (covered_lines.to_f / total_lines * 100).round(2)

puts "\n=== Overall Coverage ===\n"
puts "Total Lines: #{total_lines}"
puts "Covered Lines: #{covered_lines}"
puts "Coverage: #{overall_percentage}%"