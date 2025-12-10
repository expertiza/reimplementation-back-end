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

echo "Step 5: Running schema transformations..."
# Disable SSL because the local MySQL instance uses a self-signed cert
mysql --ssl=0 -h db -uroot -pexpertiza reimplementation < /app/db/new_seed.sql

echo "Step 6: Seeding the database..." 
rake db:seed

echo "Step 7: Starting the Rails server..."
rails s -p 3002 -b '0.0.0.0'
