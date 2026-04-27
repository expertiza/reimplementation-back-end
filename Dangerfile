# frozen_string_literal: true

CURRENT_MAINTAINERS = %w[
  efg
  Winbobob
  TheAkbar
  johnbumgardner
  nnhimes
].freeze

ADDED_FILES    = git.added_files
DELETED_FILES  = git.deleted_files
MODIFIED_FILES = git.modified_files
RENAMED_FILES  = git.renamed_files
TOUCHED_FILES  = ADDED_FILES + DELETED_FILES + MODIFIED_FILES + RENAMED_FILES
LOC            = git.lines_of_code
COMMITS        = git.commits

PR_AUTHOR = github.respond_to?(:pr_author) ? github.pr_author.to_s : ''
PR_TITLE  = github.respond_to?(:pr_title) ? github.pr_title.to_s : ''
PR_DIFF   = github.respond_to?(:pr_diff) ? github.pr_diff.to_s : ''
PR_ADDED  = PR_DIFF
            .split("\n")
            .select { |loc| loc.start_with?('+') && !loc.include?('+++ b') }
            .join("\n")

def added_lines_for(file)
  diff = git.diff_for_file(file)
  patch = diff&.patch.to_s
  patch
    .split("\n")
    .select { |loc| loc.start_with?('+') && !loc.include?('+++ b') }
end

def warning_message_of_config_file_change(filename, regex)
  return if CURRENT_MAINTAINERS.include?(PR_AUTHOR)
  return unless TOUCHED_FILES.grep(regex).any?

  fail("You changed #{filename}; please double-check whether this is necessary.", sticky: true)
end

# ------------------------------------------------------------------------------
# 0. Welcome message
# ------------------------------------------------------------------------------
unless CURRENT_MAINTAINERS.include?(PR_AUTHOR)
  if PR_TITLE =~ /E[0-9]{4}/
    message(
      markdown(
        <<~MARKDOWN
          Thanks for the pull request, and welcome! The Expertiza team is excited to review your changes, and you should hear from us soon.

          Please make sure the PR passes all checks and you have run `rubocop -a` to autocorrect issues before requesting a review.

          This repository is being automatically checked for code-quality issues using CodeRabbit, Danger, and CI workflows. Please address newly introduced issues before marking the PR ready for review.

          Also, please spend some time looking at the instructions at the top of your course project writeup.
          If you have any questions, please send email to <a href="mailto:expertiza-support@lists.ncsu.edu">expertiza-support@lists.ncsu.edu</a>.
        MARKDOWN
      )
    )
  else
    message(
      markdown(
        <<~MARKDOWN
          Thanks for the pull request, and welcome! The Expertiza team is excited to review your changes, and you should hear from us soon.

          Please make sure the PR passes all checks and you have run `rubocop -a` to autocorrect issues before requesting a review.

          This repository is being automatically checked for code-quality issues using CodeRabbit, Danger, and CI workflows. Please address newly introduced issues before marking the PR ready for review.

          If you have any questions, please send email to <a href="mailto:expertiza-support@lists.ncsu.edu">expertiza-support@lists.ncsu.edu</a>.
        MARKDOWN
      )
    )
  end
end

# ------------------------------------------------------------------------------
# 1. Your pull request should not be too big (more than 500 LoC).
# ------------------------------------------------------------------------------
if LOC > 500
  warn(
    markdown(
      <<~MARKDOWN
        Your pull request is more than 500 LoC.
        Please make sure you did not commit unnecessary changes, such as `schema.rb`, `node_modules`, or changelog noise.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 2. Your pull request should not be too small (less than 50 LoC).
# ------------------------------------------------------------------------------
if PR_TITLE =~ /E[0-9]{4}/ && LOC < 50
  warn(
    markdown(
      <<~MARKDOWN
        Your pull request is less than 50 LoC.
        If you are finished refactoring the code, please consider writing corresponding tests.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 3. Your pull request should not touch too many files (more than 30 files).
# ------------------------------------------------------------------------------
if TOUCHED_FILES.size > 30
  warn(
    markdown(
      <<~MARKDOWN
        Your pull request touches more than 30 files.
        Please make sure you did not commit unnecessary changes, such as `node_modules`, `vendor`, or workflow churn.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 4. Your pull request should not have too many duplicated commit messages.
# ------------------------------------------------------------------------------
messages = COMMITS.map(&:message)
has_many_dup_commit_messages = messages.uniq.any? { |msg| messages.count(msg) >= 5 }

if has_many_dup_commit_messages
  warn(
    markdown(
      <<~MARKDOWN
        Your pull request has many duplicated commit messages. Please try to squash similar commits
        and use meaningful commit messages later.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 5. Your pull request is "work in progress" and it will not be merged.
# ------------------------------------------------------------------------------
if PR_TITLE.match?(/\bWIP\b/i)
  warn(
    markdown(
      <<~MARKDOWN
        This pull request is classed as `Work in Progress`. It cannot be merged right now.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 6. Your pull request should not contain "Todo" or "Fixme" keyword.
# ------------------------------------------------------------------------------
if PR_ADDED.match?(/\b(TODO|FIXME)\b/i)
  warn(
    markdown(
      <<~MARKDOWN
        This pull request contains `TODO` or `FIXME` task(s); please fix them.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 7. Your pull request should not include temp, tmp, cache file.
# ------------------------------------------------------------------------------
if ADDED_FILES.grep(/temp|tmp|cache/i).any?
  fail(
    markdown(
      <<~MARKDOWN
        You committed `temp`, `tmp` or `cache` files. Please remove them.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 8. Your pull request should avoid using global variables and/or class variables.
# ------------------------------------------------------------------------------
(ADDED_FILES + MODIFIED_FILES + RENAMED_FILES).each do |file|
  next unless file.end_with?('.rb')

  added_lines = added_lines_for(file).join("\n")
  next unless added_lines.match?(/\$[A-Za-z0-9_]+/) || added_lines.match?(/@@[A-Za-z0-9_]+/)

  warn(
    markdown(
      <<~MARKDOWN
        You are using global variables (`$`) or class variables (`@@`); please double-check whether this is necessary.
      MARKDOWN
    ),
    sticky: true
  )
  break
end

# ------------------------------------------------------------------------------
# 9. Your pull request should avoid keeping debugging code.
# ------------------------------------------------------------------------------
if PR_ADDED.include?('puts ') ||
   PR_ADDED.include?('print ') ||
   PR_ADDED.include?('binding.pry') ||
   PR_ADDED.include?('debugger;') ||
   PR_ADDED.include?('console.log')
  warn('You are including debug code in your pull request, please remove it.', sticky: true)
end

# ------------------------------------------------------------------------------
# 10. You should write tests after making changes to the application.
# ------------------------------------------------------------------------------
if TOUCHED_FILES.grep(%r{^app/}).any? && TOUCHED_FILES.grep(%r{^spec/}).empty?
  warn(
    markdown(
      <<~MARKDOWN
        There are code changes, but no corresponding tests.
        Please include tests if this PR introduces any modifications in behavior.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 11. Your pull request should not include skipped/pending/focused test cases.
# ------------------------------------------------------------------------------
(ADDED_FILES + MODIFIED_FILES + RENAMED_FILES).each do |file|
  next unless file.end_with?('_spec.rb')

  added_lines = added_lines_for(file).join("\n")
  if added_lines.include?('xdescribe') ||
     added_lines.include?('xspecify') ||
     added_lines.include?('xexample') ||
     added_lines.include?('xit') ||
     added_lines.include?('skip(') ||
     added_lines.include?('skip ') ||
     added_lines.include?('pending(') ||
     added_lines.include?('fdescribe') ||
     added_lines.include?('fit')
    warn(
      markdown(
        <<~MARKDOWN
          There are one or more skipped, pending, or focused test cases in your pull request. Please fix them.
        MARKDOWN
      ),
      sticky: true
    )
    break
  end
end

# ------------------------------------------------------------------------------
# 12. Unit tests and integration tests should avoid using "create" keyword.
# ------------------------------------------------------------------------------
(ADDED_FILES + MODIFIED_FILES + RENAMED_FILES).each do |file|
  next unless file.match?(%r{spec/models}) || file.match?(%r{spec/controllers})

  added_lines = added_lines_for(file).join("\n")
  next unless added_lines.match?(/create\(/)

  warn(
    markdown(
      <<~MARKDOWN
        Using `create` in unit tests or integration tests may be overkill. Try to use `build` or `double` instead.
      MARKDOWN
    ),
    sticky: true
  )
  break
end

# ------------------------------------------------------------------------------
# 13. RSpec tests should avoid using "should" keyword.
# ------------------------------------------------------------------------------
(ADDED_FILES + MODIFIED_FILES + RENAMED_FILES).each do |file|
  next unless file.end_with?('_spec.rb')

  added_lines = added_lines_for(file).join("\n")
  next unless added_lines.include?('.should')

  warn(
    markdown(
      <<~MARKDOWN
        The `should` syntax is deprecated in RSpec 3. Please use `expect` syntax instead.
        Even in test descriptions, please avoid using `should`.
      MARKDOWN
    ),
    sticky: true
  )
  break
end

# ------------------------------------------------------------------------------
# 14. Your RSpec testing files do not need to require helper files.
# ------------------------------------------------------------------------------
if PR_ADDED.include?("require 'rspec'") ||
   PR_ADDED.include?('require "rspec"') ||
   PR_ADDED.include?("require 'spec_helper'") ||
   PR_ADDED.include?('require "spec_helper"') ||
   PR_ADDED.include?("require 'rails_helper'") ||
   PR_ADDED.include?('require "rails_helper"') ||
   PR_ADDED.include?("require 'test_helper'") ||
   PR_ADDED.include?('require "test_helper"') ||
   PR_ADDED.include?("require 'factory_girl_rails'") ||
   PR_ADDED.include?('require "factory_girl_rails"') ||
   PR_ADDED.include?("require 'factory_bot_rails'") ||
   PR_ADDED.include?('require "factory_bot_rails"')
  warn(
    markdown(
      <<~MARKDOWN
        You are requiring `rspec`, fixture-related gems, or helper methods in RSpec tests.
        These have already been included, so you do not need to require them again. Please remove them.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 15. You should avoid committing text files for RSpec tests.
# ------------------------------------------------------------------------------
if TOUCHED_FILES.grep(/spec.*\.(txt|csv)$/).any?
  warn('You committed text files (`*.txt` or `*.csv`) for RSpec tests; please double-check whether this is necessary.', sticky: true)
end

# ------------------------------------------------------------------------------
# 16. Your pull request should not change or add *.md files unless you have a good reason.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) && TOUCHED_FILES.grep(/\.md$/).any?
  warn(
    markdown(
      <<~MARKDOWN
        You changed MARKDOWN (`*.md`) documents; please double-check whether it is necessary to do so.
        Alternatively, you can insert project-related content in the description field of the pull request.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 17. Your pull request should not change DB schema unless there is new DB migration.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) &&
   TOUCHED_FILES.grep(%r{db/migrate}).empty? &&
   (MODIFIED_FILES.grep(/schema\.rb$/).any? || TOUCHED_FILES.grep(/schema\.json$/).any?)
  warn(
    markdown(
      <<~MARKDOWN
        You should commit changes to the DB schema (`db/schema.rb`) only if you have created new DB migrations.
        Please double check your code. If you did not aim to change the DB, please revert the DB schema changes.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 18. Your pull request should not modify *.yml or *.yml.example file.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) && TOUCHED_FILES.grep(/\.ya?ml(\.example)?$/).any?
  warn(
    markdown(
      <<~MARKDOWN
        You changed YAML (`*.yml`, `*.yaml`) or example config files; please double-check whether this is necessary.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 19. Your pull request should not modify test-related helper files.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) &&
   (MODIFIED_FILES.grep(/rails_helper\.rb$/).any? || MODIFIED_FILES.grep(/spec_helper\.rb$/).any?)
  warn(
    markdown(
      <<~MARKDOWN
        You should not change `rails_helper.rb` or `spec_helper.rb` without a strong reason; please double-check these changes.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 20. Your pull request should not modify Gemfile, Gemfile.lock.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) &&
   (MODIFIED_FILES.include?('Gemfile') || MODIFIED_FILES.include?('Gemfile.lock'))
  warn(
    markdown(
      <<~MARKDOWN
        You are modifying `Gemfile` or `Gemfile.lock`, please double check whether it is necessary.
        Add a new gem only if you have a very good reason, and please revert lockfile noise made by the IDE.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 21-33. Configuration files should not change casually.
# ------------------------------------------------------------------------------
warning_message_of_config_file_change('.bowerrc', /\.bowerrc$/)
warning_message_of_config_file_change('.gitignore', /\.gitignore$/)
warning_message_of_config_file_change('.mention-bot', /\.mention-bot$/)
warning_message_of_config_file_change('.rspec', /\.rspec$/)
warning_message_of_config_file_change('Capfile', /(^|\/)Capfile$/)
warning_message_of_config_file_change('Dangerfile', /(^|\/)Dangerfile$/)
warning_message_of_config_file_change('Guardfile', /(^|\/)Guardfile$/)
warning_message_of_config_file_change('LICENSE', /(^|\/)LICENSE$/)
warning_message_of_config_file_change('Procfile', /(^|\/)Procfile$/)
warning_message_of_config_file_change('Rakefile', /(^|\/)Rakefile$/)
warning_message_of_config_file_change('bower.json', /(^|\/)bower\.json$/)
warning_message_of_config_file_change('config.ru', /(^|\/)config\.ru$/)
warning_message_of_config_file_change('setup.sh', /(^|\/)setup\.sh$/)

# ------------------------------------------------------------------------------
# 34. The PR should not modify vendor folder.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) && TOUCHED_FILES.grep(%r{^vendor/}).any?
  warn(
    markdown(
      <<~MARKDOWN
        You modified the `vendor` folder; please double-check whether it is necessary.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 35. You should not modify /spec/factories/ folder.
# ------------------------------------------------------------------------------
if !CURRENT_MAINTAINERS.include?(PR_AUTHOR) && TOUCHED_FILES.grep(%r{^spec/factories/}).any?
  warn(
    markdown(
      <<~MARKDOWN
        You modified `spec/factories/`; please double-check whether it is necessary.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 36. You should not commit .vscode folder to your pull request.
# ------------------------------------------------------------------------------
if ADDED_FILES.grep(/\.vscode/).any?
  warn(
    markdown(
      <<~MARKDOWN
        You committed `.vscode` folder; please remove it.
      MARKDOWN
    ),
    sticky: true
  )
end

# ------------------------------------------------------------------------------
# 37-41. RSpec tests should avoid shallow tests.
# ------------------------------------------------------------------------------
(ADDED_FILES + MODIFIED_FILES + RENAMED_FILES).each do |file|
  next unless file.end_with?('_spec.rb')

  added_lines_arr = added_lines_for(file)
  added_lines = added_lines_arr.join("\n")
  num_of_tests = added_lines.scan(/\+\s*it\s*['"]/).count
  num_of_expect_key_words = added_lines.scan(/\+\s*expect\s*(\(|\{|do)/).count
  num_of_commented_out_expect_key_words = added_lines.scan(/\+\s*#\s*expect\s*(\(|\{|do)/).count
  num_of_expectation_without_matchers = added_lines_arr.count do |loc|
    loc.match?(/^\+\s*expect\s*[\(\{]/) && !loc.match?(/\.(to|not_to|to_not)/)
  end
  num_of_expectation_not_focus_on_real_value = added_lines_arr.count do |loc|
    loc.match?(/^\+\s*expect\s*[\(\{]/) && loc.match?(/\.(not_to|to_not)\s*(be_nil|be_empty|eq 0|eql 0|equal 0)/)
  end
  num_of_wildcard_argument_matchers = added_lines.scan(/\((anything|any_args)\)/).count
  num_of_expectations_on_page = added_lines.scan(/\+\s*expect\s*\(page\)/).count

  if num_of_wildcard_argument_matchers >= 5
    warn(
      markdown(
        <<~MARKDOWN
          There are many wildcard argument matchers (e.g., `anything`, `any_args`) in your tests.
          To avoid shallow tests, please avoid wildcard matchers.
        MARKDOWN
      ),
      sticky: true
    )
    break
  elsif num_of_expect_key_words < num_of_tests || num_of_commented_out_expect_key_words.positive?
    warn(
      markdown(
        <<~MARKDOWN
          One or more of your tests do not have expectations or you commented out some expectations.
          To avoid shallow tests, please write at least one expectation for each test and do not comment out expectations.
        MARKDOWN
      ),
      sticky: true
    )
    break
  elsif num_of_expectation_without_matchers.positive?
    warn(
      markdown(
        <<~MARKDOWN
          One or more of your test expectations do not have matchers.
          To avoid shallow tests, please include matchers such as comparisons, object state changes, or explicit error handling.
        MARKDOWN
      ),
      sticky: true
    )
    break
  elsif num_of_expectation_not_focus_on_real_value.positive?
    warn(
      markdown(
        <<~MARKDOWN
          One or more of your test expectations only focus on the return value not being `nil`, `empty`, or `0` without testing the real value.
          To avoid shallow tests, please write expectations that verify the real value.
        MARKDOWN
      ),
      sticky: true
    )
    break
  elsif num_of_expect_key_words - num_of_expectations_on_page < num_of_tests
    warn(
      markdown(
        <<~MARKDOWN
          In your tests, there are many expectations of elements on pages, which is good.
          To avoid shallow tests, please write more expectations to validate other things, such as database records or dynamically generated contents.
        MARKDOWN
      ),
      sticky: true
    )
    break
  end
end
