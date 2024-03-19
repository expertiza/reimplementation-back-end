#!/bin/bash
   
echo "=== Running commands in the 'app' terminal ==="
echo "Step 1: Bundling dependencies..."
docker compose exec app bundle install
  
echo "Step 2: Creating the database..."
docker compose exec app rake db:create
 
echo "Step 3: Running database migrations..."
docker compose exec app rake db:migrate

echo "Step 4: Seeding the database..." 
docker compose exec app rake db:seed

echo "Step 5: Starting the Rails server..."
docker compose exec app rails s -p 3002 -b '0.0.0.0'
 
echo "=== Setup script completed successfully ==="
