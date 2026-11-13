#!/bin/bash

echo "=== Starting Expertiza application ==="

echo "Removing existing server PID file if present..."
rm -f /app/tmp/pids/server.pid

# Ensure test database is configured when running in test mode
if [ "${RAILS_ENV:-development}" = "test" ] && [ -z "${TEST_DATABASE_URL:-}" ]; then
  echo "ERROR: TEST_DATABASE_URL must be configured for test mode." >&2
  exit 1
fi

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

  echo "Checking dependencies..."
  bundle check || bundle install || exit 1

  if [ "${RAILS_ENV:-development}" = "development" ]; then
     echo "Preparing development database..."
     bundle exec rails db:prepare || exit 1
  else
     echo "Preparing test database..."
     bundle exec rails db:create || exit 1
     bundle exec rails db:migrate || exit 1
     echo "Skipping database seeding in test environment."
  fi

else
  echo "ERROR: Unsupported RAILS_ENV: ${RAILS_ENV}" >&2
  exit 1
fi

echo "Starting application: $*"
exec "$@"
