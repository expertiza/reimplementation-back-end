#!/bin/bash

echo "=== Running commands in the 'app' terminal ==="
echo "Step 1: Bundling dependencies..."
docker exec -it reimplementation-back-end-app-1 bundle install

echo "Step 2: Creating the database..."
docker exec -it reimplementation-back-end-app-1 rake db:create

echo "Step 3: Running database migrations..."
docker exec -it reimplementation-back-end-app-1 rake db:migrate

echo "Step 4: Seeding the database..."
docker exec -it reimplementation-back-end-app-1 rake db:migrate

echo "Step 5: Starting the Rails server..."
docker exec -it reimplementation-back-end-app-1 rails s -p 4000 -b '0.0.0.0' &

# Sleep to allow the Rails server to start
sleep 10

echo "=== Running commands in the MySQL container ==="
echo "Step 5: Inserting data into the institutions table..."
docker exec -it reimplementation-back-end-db-1 mysql -u dev -pexpertiza -e "use reimplementation_development; INSERT INTO institutions (name, created_at, updated_at) VALUES ('North Carolina State University', NOW(), NOW());"

echo "=== Running commands in the 'reimplementation-back-end-app' container ==="
echo "Step 6: Opening Rails console..."
docker exec -it reimplementation-back-end-app-1 rails console

echo "Step 7: Creating a hashed password..."
hashed_password=$(docker exec -it reimplementation-back-end-app-1 ruby -e "require 'bcrypt'; puts BCrypt::Password.create('password123')")

echo "Step 8: Inserting data into the users table..."
docker exec -it reimplementation-back-end-db-1 mysql -u root -pexpertiza -e "use reimplementation_development; INSERT INTO users (name, email, password_digest, role_id, created_at, updated_at, full_name, institution_id) VALUES ('admin', 'admin2@example.com', '$hashed_password', 1, NOW(), NOW(), 'admin admin', 1);"

echo "=== Setup script completed successfully ==="
