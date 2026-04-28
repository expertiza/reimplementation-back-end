# Expertiza Backend Re-Implementation

The following steps can be used to run only the tests relevant to this project.

In spec_helper.rb:

1. Add the following line to the require section:

```
require 'simplecov-html'
```

2. Modify the SimpleCov.formatter assignment to be the following:

```
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
])
```

3. Replace the if !ENV['COVERAGE_STARTED'] block with the following:

```
if !ENV['COVERAGE_STARTED']
  SimpleCov.start 'rails' do
    track_files 'app/models/{questionnaire,question_advice,course}.rb'
    tracked = %w[
      app/models/questionnaire.rb
      app/models/question_advice.rb
      app/models/course.rb
    ].map { |path| File.expand_path(path, SimpleCov.root) }

    add_filter do |src|
      !tracked.include?(src.filename)
    end
  end
  ENV['COVERAGE_STARTED'] = 'true'
end
```

Then, run the test suite using the following:

```
bundle exec rspec spec/models/questionnaire_spec.rb spec/models/course_spec.rb spec/models/question_advice_spec.rb 
```

## Development Environment

* Ruby version - 3.4.5

### Prerequisites
- Verify that [Docker Desktop](https://www.docker.com/products/docker-desktop/) is installed and running.
- [Download](https://www.jetbrains.com/ruby/download/) RubyMine
- Make sure that the Docker plugin [is enabled](https://www.jetbrains.com/help/ruby/docker.html#enable_docker).

### Instructions
Tutorial: [Docker Compose as a remote interpreter](https://www.jetbrains.com/help/ruby/using-docker-compose-as-a-remote-interpreter.html)

### Video Tutorial

<a href="http://www.youtube.com/watch?feature=player_embedded&v=BHniRaZ0_JE
" target="_blank"><img src="http://img.youtube.com/vi/BHniRaZ0_JE/maxresdefault.jpg" 
alt="IMAGE ALT TEXT HERE" width="560" height="315" border="10" /></a>

### Database Credentials
- username: root
- password: expertiza
