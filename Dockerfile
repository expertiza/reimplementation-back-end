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

# Set the working directory
WORKDIR /app

# Copy your application files from current location to WORKDIR
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN gem update --system && gem install bundler:2.4.14
RUN bundle install

COPY . .

RUN mv /app/setup.sh /setup.sh && chmod +x /setup.sh

EXPOSE 3002 

# Set the entry point
ENTRYPOINT ["/setup.sh"]

CMD ["rails", "server", "--port", "3002", "--binding", "0.0.0.0", "--using", "puma"]
