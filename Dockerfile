FROM ruby:3.2.1

LABEL maintainer="Ankur Mundra <ankurmundra0212@gmail.com>"
# Install dependencies
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Set the working directory
WORKDIR /app

# Copy your application files from current location to WORKDIR
COPY . .

# Install Ruby dependencies
RUN gem update --system && gem install bundler:2.4.7
RUN bundle install

EXPOSE 4000

CMD ["bash"]
