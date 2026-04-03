#!/bin/bash

set -e

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"

until nc -z "${DB_HOST}" "${DB_PORT}"; do
  echo "Waiting for database connection at ${DB_HOST}:${DB_PORT}..."
  sleep 5
done

echo "Removing existing server PID file if any..."
rm -f /app/tmp/pids/server.pid

echo "Checking Ruby dependencies..."
bundle check || bundle install

echo "Creating the database if needed..."
bin/rails db:create

echo "Running database migrations..."
bin/rails db:migrate

if [ "${SEED_DB:-false}" = "true" ]; then
  echo "Seeding the database..."
  bin/rails db:seed
fi

exec "$@"
