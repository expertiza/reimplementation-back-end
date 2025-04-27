# Dangerfile

# --- PR Size Checks ---
warn("Pull request is too big (more than 500 LoC).") if git.lines_of_code > 500
warn("Pull request is too small (less than 50 LoC).") if git.lines_of_code < 50

# --- File Change Checks ---
warn("Pull request touches too many files (more than 30 files).") if git.modified_files.count > 30

# --- Commit Message Checks ---
commit_messages = git.commits.map(&:message)
duplicated_commits = commit_messages.group_by(&:itself).select { |_, v| v.size > 1 }
warn("Pull request has duplicated commit messages.") if duplicated_commits.any?

# --- TODO/FIXME Checks ---
todo_fixme = (git.modified_files + git.added_files).any? do |file|
  File.read(file).match?(/\b(TODO|FIXME)\b/i)
end
warn("Pull request contains TODO or FIXME comments.") if todo_fixme

# --- Temp File Checks ---
temp_files = git.added_files.any? { |file| file.match?(/(tmp|temp|cache)/i) }
warn("Pull request includes temp, tmp, or cache files.") if temp_files

# --- Missing Test Checks ---
warn("There are no test changes in this PR.") if (git.modified_files + git.added_files).none? { |f| f.include?('spec/') || f.include?('test/') }


# --- .md File Changes ---
md_changes = git.modified_files.any? { |file| file.end_with?('.md') }
warn("Pull request modifies markdown files (*.md). Make sure you have a good reason.") if md_changes

# --- DB Schema Changes ---
schema_changes = git.modified_files.any? { |file| file.match?(/db\/schema\.rb$/) }
unless git.modified_files.any? { |file| file.match?(/db\/migrate\//) }
  warn("Schema changes detected without a corresponding DB migration.") if schema_changes
end

# --- Config/Setup File Changes (selected ones not excluded) ---
config_files = %w[
  config/database.yml
  config/secrets.yml
  config/secrets.yml.example
  config/settings.yml
  config/settings.yml.example
  setup.sh
  config.ru
]
changed_config_files = git.modified_files.select { |file| config_files.include?(file) }
warn("Pull request modifies config or setup files: #{changed_config_files.join(', ')}.") if changed_config_files.any?


# --- Shallow Tests (RSpec) ---
# (Rules 37-41 — Shallow tests — assuming you want them included)
shallow_test_files = git.modified_files.select { |file| file.include?('spec/') }
shallow_test_warning = shallow_test_files.any? do |file|
  File.read(file).match?(/\bit\b|\bspecify\b/)
end
warn("RSpec tests seem shallow (single `it` blocks or no context). Consider improving test structure.") if shallow_test_warning
