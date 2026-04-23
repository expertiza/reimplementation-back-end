FROM ruby:3.2.7

LABEL maintainer="Ankur Mundra <ankurmundra0212@gmail.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl netcat-openbsd && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem update --system && gem install bundler:2.4.7

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN chmod +x /app/setup.sh

EXPOSE 3002

ENTRYPOINT ["/app/setup.sh"]
