#!/bin/bash

# Test script for Real-Time Polling App API
echo "Testing Real-Time Polling App API..."
echo "=================================="

BASE_URL="http://localhost:3000/api/v1"

# Test 1: Register a new user
echo -e "\n1. Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }')

echo "Registration Response: $REGISTER_RESPONSE"

# Test 2: Login with the created user
echo -e "\n2. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "password123"
  }')

echo "Login Response: $LOGIN_RESPONSE"

# Extract token from login response
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Extracted Token: $TOKEN"

if [ -z "$TOKEN" ]; then
    echo "Failed to get token, exiting..."
    exit 1
fi

# Test 3: Get current user info
echo -e "\n3. Testing get current user..."
USER_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN")

echo "User Info Response: $USER_RESPONSE"

# Test 4: Get all polls
echo -e "\n4. Testing get all polls..."
POLLS_RESPONSE=$(curl -s -X GET "$BASE_URL/polls" \
  -H "Authorization: Bearer $TOKEN")

echo "Polls Response: $POLLS_RESPONSE"

# Test 5: Create a new poll
echo -e "\n5. Testing create poll..."
CREATE_POLL_RESPONSE=$(curl -s -X POST "$BASE_URL/polls" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "poll": {
      "title": "What is your favorite IDE?",
      "description": "Choose your preferred integrated development environment",
      "expires_at": "2025-08-14T14:00:00Z"
    },
    "options": ["VS Code", "IntelliJ IDEA", "Vim", "Sublime Text"]
  }')

echo "Create Poll Response: $CREATE_POLL_RESPONSE"

# Extract poll ID from response
POLL_ID=$(echo $CREATE_POLL_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Created Poll ID: $POLL_ID"

if [ ! -z "$POLL_ID" ]; then
    # Test 6: Get specific poll
    echo -e "\n6. Testing get specific poll..."
    SPECIFIC_POLL_RESPONSE=$(curl -s -X GET "$BASE_URL/polls/$POLL_ID" \
      -H "Authorization: Bearer $TOKEN")

    echo "Specific Poll Response: $SPECIFIC_POLL_RESPONSE"

    # Test 7: Vote on the poll (get first option ID)
    OPTION_ID=$(echo $SPECIFIC_POLL_RESPONSE | grep -o '"id":[0-9]*' | sed -n '2p' | cut -d':' -f2)
    echo "Voting for Option ID: $OPTION_ID"

    if [ ! -z "$OPTION_ID" ]; then
        echo -e "\n7. Testing vote casting..."
        VOTE_RESPONSE=$(curl -s -X POST "$BASE_URL/polls/$POLL_ID/votes" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $TOKEN" \
          -d "{
            \"vote\": {
              \"option_id\": $OPTION_ID
            }
          }")

        echo "Vote Response: $VOTE_RESPONSE"
    fi
fi

# Test 8: Get user's own polls
echo -e "\n8. Testing get my polls..."
MY_POLLS_RESPONSE=$(curl -s -X GET "$BASE_URL/polls/my_polls" \
  -H "Authorization: Bearer $TOKEN")

echo "My Polls Response: $MY_POLLS_RESPONSE"

echo -e "\n=================================="
echo "API testing completed!"
