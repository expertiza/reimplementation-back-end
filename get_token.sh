#!/usr/bin/env bash

# Script to get a JWT token for testing

echo "Getting JWT token for quinn_johns..."
echo ""

# Make login request
response=$(curl -s -X POST http://152.7.176.23:3002/login \
  -H "Content-Type: application/json" \
  -d '{
    "user_name": "quinn_johns",
    "password": "password123"
  }')

# Extract token
token=$(echo $response | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$token" ]; then
  echo "❌ Failed to get token. Response:"
  echo $response
  echo ""
  echo "Trying with default password 'password'..."
  
  response=$(curl -s -X POST http://152.7.176.23:3002/login \
    -H "Content-Type: application/json" \
    -d '{
      "user_name": "quinn_johns",
      "password": "password"
    }')
  
  token=$(echo $response | grep -o '"token":"[^"]*' | cut -d'"' -f4)
  
  if [ -z "$token" ]; then
    echo "❌ Still failed. Response:"
    echo $response
    exit 1
  fi
fi

echo "✅ Successfully obtained JWT token!"
echo ""
echo "Token: $token"
echo ""
echo "To use this token in your browser:"
echo "1. Open Developer Tools (F12)"
echo "2. Go to Console tab"
echo "3. Run: localStorage.setItem('jwt', '$token')"
echo "4. Refresh the page"
echo ""
echo "Or test the API directly:"
echo "curl -H 'Authorization: Bearer $token' http://152.7.176.23:3002/api/v1/sign_up_topics?assignment_id=1"
