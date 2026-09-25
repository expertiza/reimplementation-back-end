FROM ruby:3.4.5

LABEL maintainer="Ankur Mundra <ankurmundra0212@gmail.com>"
# Install dependencies
RUN apt-get update && \
    apt-get install -y curl netcat-openbsd

# Set the working directory
WORKDIR /app

# Copy your application files from current location to WORKDIR
COPY . .

# Install Ruby dependencies
RUN gem update --system && gem install bundler:2.4.7
RUN bundle install

EXPOSE 3002 

# Set the entry point
ENTRYPOINT ["/app/setup.sh"]
