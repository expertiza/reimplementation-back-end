FROM ruby:3.3.4

LABEL maintainer="Ankur Mundra <ankurmundra0212@gmail.com>"

# Install necessary system dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    netcat-openbsd && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Set the working directory
WORKDIR /app

# Copy your application files from the current location to WORKDIR
COPY . .

# Install Ruby dependencies (with updated bundler version)
RUN gem update --system && gem install bundler:2.4.7
RUN bundle install --jobs 4 --retry 3

# Expose the necessary port for Rails server
EXPOSE 3002

# Set the entry point (run your setup.sh script if needed)
ENTRYPOINT ["/app/setup.sh"]
