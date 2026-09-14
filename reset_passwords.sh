#!/bin/bash
# Quick password reset script using the API
# Make sure the backend is running first
# This calls the forgot-password endpoint to get a reset token, then resets passwords

BACKEND_URL="http://localhost:8000"  # Change to your deployed URL
PASSWORD="test123"

echo "🔐 Resetting test user passwords via API..."
echo ""

# Function to reset password for a user
reset_password() {
    local email=$1
    echo "Resetting password for: $email"
    
    # Step 1: Request password reset (get development token)
    response=$(curl -s -X POST "$BACKEND_URL/api/auth/forgot-password" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"$email\"}")
    
    echo "Response: $response"
    
    # Extract the development_reset_token (only in dev/debug mode)
    token=$(echo $response | grep -oP '"development_reset_token": "\K[^"]*')
    
    if [ -z "$token" ]; then
        echo "❌ Failed to get reset token for $email"
        echo "Make sure DEBUG=true and APP_ENV != production"
        return 1
    fi
    
    echo "✅ Reset token received"
    
    # Step 2: Reset password with the token
    reset_response=$(curl -s -X POST "$BACKEND_URL/api/auth/reset-password" \
      -H "Content-Type: application/json" \
      -d "{\"token\": \"$token\", \"new_password\": \"$PASSWORD\"}")
    
    echo "Reset response: $reset_response"
    echo "---"
}

# Reset passwords for all test users
reset_password "admin@zhuzen.com"
reset_password "manager@zhuzen.com"
reset_password "tech1@zhuzen.com"
reset_password "tech2@zhuzen.com"
reset_password "customer1@example.com"

echo ""
echo "✅ All passwords reset to: $PASSWORD"
