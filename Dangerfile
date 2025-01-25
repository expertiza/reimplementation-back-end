# Rule 1: PR should not be too small (less than 50 lines of code)
fail("Your pull request should not be too small (less than 50 LoC).") if git.lines_of_code < 50

# Rule 2: PR should not touch too many files (more than 30 files)
fail("Your pull request should not touch too many files (more than 30 files).") if git.modified_files.size + git.added_files.size > 30

# Rule 3: PR should not have too many duplicated commit messages
github.commits.group_by(&:message).each do |message, commits|
  warn("Duplicate commit message: '#{message}' found #{commits.size} times.") if commits.size > 1
end

# Rule 4: PR marked as "Work in Progress" should not be merged
fail("Your pull request is marked as 'work in progress' and will not be merged.") if github.pr_title.downcase.include?("wip")

# Rule 5: PR should not contain "TODO" or "FIXME"
fail("Your pull request should not contain 'TODO' or 'FIXME' keywords.") if git.modified_files.any? { |file| File.read(file).include?("TODO") || File.read(file).include?("FIXME") }

# Rule 6: PR should not include temp, tmp, or cache files
temp_files = git.modified_files + git.added_files
temp_files.each do |file|
  fail("Your pull request includes temp or cache files: #{file}") if file =~ /.*(temp|tmp|cache).*/
end

# Rule 7: PR should avoid using global variables and/or class variables
fail("Your pull request should avoid using global variables or class variables.") if git.modified_files.any? { |file| File.read(file) =~ /\$[a-zA-Z_][a-zA-Z0-9_]*|@@[a-zA-Z_][a-zA-Z0-9_]*/ }

# Rule 8: PR should avoid keeping debugging code
debugging_patterns = [/binding\.pry/, /console\.log/, /debugger/]
fail("Your pull request contains debugging code.") if git.modified_files.any? do |file|
  debugging_patterns.any? { |pattern| File.read(file).match?(pattern) }
end

# Rule 9: Tests should be written after making changes
warn("You should write tests after making changes to the application.") if git.modified_files.none? { |file| file.include?("spec") || file.include?("test") }

# Rule 10: PR should not include skipped/pending/focused test cases
test_patterns = [/skip/, /pending/, /focus/]
fail("Your pull request includes skipped, pending, or focused test cases.") if git.modified_files.any? do |file|
  test_patterns.any? { |pattern| File.read(file).match?(pattern) }
end

# Rule 11: Tests should avoid using the "create" keyword
fail("Unit tests and integration tests should avoid using 'create' keyword.") if git.modified_files.any? { |file| File.read(file).include?("create") && file.include?("spec") }

# Rule 12: RSpec tests should avoid using "should" keyword
fail("RSpec tests should avoid using 'should' keyword.") if git.modified_files.any? { |file| File.read(file).include?("should") && file.include?("spec") }

# Rule 13: RSpec testing files should not require helper files explicitly
helper_files = ["rails_helper.rb", "spec_helper.rb"]
fail("Your RSpec testing files should not require helper files explicitly.") if git.modified_files.any? do |file|
  helper_files.any? { |helper| File.read(file).include?("require '#{helper}'") }
end
