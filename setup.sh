#!/bin/bash

echo "=== Running commands in the 'app' terminal ==="
echo "Step 1: Removing existing server PID file if any..."
rm -f /app/tmp/pids/server.pid

echo "Step 2: Bundling dependencies..."
bundle install
  
echo "Step 3: Creating the database..."
rake db:create
 
echo "Step 4: Running database migrations..."
rake db:migrate

echo "Step 5: Seeding the database..." 
rake db:seed

echo "Running the default command from Docker CMD:"
echo "$@"
exec "$@"
