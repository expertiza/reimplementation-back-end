# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.7
FROM ruby:$RUBY_VERSION

# Install libvips for Active Storage preview support
RUN apt-get update -qq && \
    apt-get install -y build-essential libvips && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# Rails app lives here
WORKDIR /app

# Set production environment
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_ENV="production"

# Set DATABASE_URL here
ENV DATABASE_URL="mysql2://user:password@localhost:3306/app_name"

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y yarn

# Create user and group for app
ARG UID=1000
ARG GID=1000

RUN bash -c "set -o pipefail && apt-get update \
 && apt-get install -y --no-install-recommends build-essential curl git libpq-dev \
 && curl -sSL https://deb.nodesource.com/setup_18.x | bash - \
 && curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update && apt-get install -y --no-install-recommends nodejs yarn \
 && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
 && apt-get clean \
 && groupadd -g \"${GID}\" ruby \
 && useradd --create-home --no-log-init -u \"${UID}\" -g \"${GID}\" ruby \
 && mkdir /node_modules && chown ruby:ruby -R /node_modules /app"

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN bundle exec rails assets:precompile
RUN bundle exec rails db:migrate
RUN bundle exec rails db:seed

# Expose port 3000
EXPOSE 3000

# Start the server by default, this can be overwritten at runtime
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
