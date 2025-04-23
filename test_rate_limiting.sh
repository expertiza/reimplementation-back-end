#!/bin/bash

# Test login rate limiting
echo "Testing login rate limiting..."
for i in {1..6}; do
    echo "Attempt $i:"
    response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" \
         -d '{"user_name":"testuser","password":"wrongpassword"}' \
         http://localhost:3000/login)
    status_code=${response: -3}
    body=${response:0:${#response}-3}
    echo "Status: $status_code"
    echo "Body: $body"
    echo -e "\n"
    sleep 1
done

# Test general rate limiting
echo "Testing general rate limiting..."
for i in {1..6}; do
    echo "Request $i:"
    response=$(curl -s -w "%{http_code}" http://localhost:3000/api/v1/users)
    status_code=${response: -3}
    body=${response:0:${#response}-3}
    echo "Status: $status_code"
    echo "Body: $body"
    echo -e "\n"
    sleep 0.1
done 