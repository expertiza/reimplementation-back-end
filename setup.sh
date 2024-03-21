#!/bin/bash

until nc -z -v -w30 db 3306 
do
  echo "Waiting for database connection..."
  sleep 5
done

echo "=== Running commands in the 'app' terminal ==="
echo "Step 1: Bundling dependencies..."
bundle install
  
echo "Step 2: Creating the database..."
rake db:create
 
echo "Step 3: Running database migrations..."
rake db:migrate

echo "Step 4: Seeding the database..." 
rake db:seed

echo "Step 5: Starting the Rails server..."
rails s -p 3002 -b '0.0.0.0'

