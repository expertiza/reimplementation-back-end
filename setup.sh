#!/bin/bash

until nc -z -v -w30 db 3306 
do
  echo "Waiting for database connection..."
  sleep 5
done

echo "=== Running commands in the 'app' terminal ==="
echo "Step 1: Removing existing server PID file if any..."
rm -f /app/tmp/pids/server.pid

echo "Step 2: Bundling dependencies..."
bundle install
  
echo "Step 3: Creating the database..."
rake db:create
 
echo "Step 4: Running database migrations..."
rake db:migrate

if [ "${RUN_DB_SEED}" = "true" ]; then
  echo "Step 5: Seeding the database..."
  rake db:seed
else
  echo "Step 5: Skipping seed (set RUN_DB_SEED=true to enable)."
fi

echo "Step 6: Starting the Rails server..."
rails s -p 3002 -b '0.0.0.0'
