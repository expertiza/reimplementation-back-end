FROM ruby:3.4.5

LABEL maintainer="Ankur Mundra <ankurmundra0212@gmail.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      curl \
      default-libmysqlclient-dev \
      netcat-openbsd \
      pkg-config && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.4.14 && bundle install

COPY . .

EXPOSE 3002

ENTRYPOINT ["/app/setup.sh"]
CMD ["bin/rails", "server", "-p", "3002", "-b", "0.0.0.0"]
