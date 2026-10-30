FROM ruby:3.4.5-slim

LABEL maintainer="Bestin Lalu <blalu@ncsu.edu>"

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      libyaml-dev \
      default-libmysqlclient-dev \
      pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root application user
RUN groupadd --gid 1000 rails && \
    useradd --uid 1000 --gid rails --create-home rails

# Set the working directory
WORKDIR /app

# Copy dependency files first to improve Docker layer caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN gem update --system && gem install bundler:2.4.14
RUN bundle install

# Copy the remaining application files
COPY . .

# Prepare writable application directories
RUN mkdir -p /app/tmp/pids /app/log /app/storage && \
    mv /app/setup.sh /setup.sh && \
    chmod +x /setup.sh && \
    chown -R rails:rails \
      /app/tmp /app/log /app/storage /usr/local/bundle

# Run the Rails application as a non-root user
USER rails

EXPOSE 3002 

# Set the entry point
ENTRYPOINT ["/setup.sh"]

CMD ["rails", "server", "--port", "3002", "--binding", "0.0.0.0", "--using", "puma"]
