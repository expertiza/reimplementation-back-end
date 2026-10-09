#!/bin/bash

echo "=== Starting Expertiza application ==="

echo "Removing existing server PID file if present..."
rm -f /app/tmp/pids/server.pid

if [ "${RAILS_ENV:-development}" = "production" ]; then
  echo "Production environment detected."

  # Production must use an external database.
  if [ -z "${DATABASE_URL:-}" ]; then
    echo "ERROR: DATABASE_URL must be configured for production." >&2
    exit 1
  fi

  echo "Skipping automatic database creation, migration, and seeding."

elif [ "${RAILS_ENV:-development}" = "development" ] || [ "${RAILS_ENV}" = "test" ]; then
  echo "Development/test environment detected."

  echo "Installing dependencies..."
  bundle install || exit 1

  echo "Creating database if necessary..."
  rake db:create || exit 1

  echo "Running database migrations..."
  rake db:migrate || exit 1

  echo "Seeding database..."
  rake db:seed

else
  echo "ERROR: Unsupported RAILS_ENV: ${RAILS_ENV}" >&2
  exit 1
fi

echo "Starting application: $*"
exec "$@"
