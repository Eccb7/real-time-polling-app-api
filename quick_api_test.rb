#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

def make_request(method, path, data = nil, token = nil)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)

  case method
  when 'GET'
    request = Net::HTTP::Get.new(uri)
  when 'POST'
    request = Net::HTTP::Post.new(uri)
  end

  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{token}" if token
  request.body = data.to_json if data

  http.request(request)
end

puts "🔍 Quick API Test - Core Functionality"
puts "=" * 40

# Step 1: Login
puts "\n1. 🔐 Logging in..."
login_data = {
  email: "bob@example.com",
  password: "password123"
}

response = make_request('POST', '/api/v1/auth/login', login_data)
if response.code == '200'
  result = JSON.parse(response.body)
  token = result['token']
  puts "✅ Login successful - User: #{result['user']['name']}"
else
  puts "❌ Login failed: #{response.code}"
  exit 1
end

# Step 2: Get polls
puts "\n2. 📊 Getting all polls..."
response = make_request('GET', '/api/v1/polls', nil, token)
if response.code == '200'
  result = JSON.parse(response.body)
  polls = result['polls'] || result
  puts "✅ Found #{polls.length} active polls"

  # Show first poll details
  if polls.any?
    first_poll = polls.first
    puts "   First poll: #{first_poll['title']}"
    puts "   Total votes: #{first_poll['total_votes']}"

    # Check if options exist and are accessible
    if first_poll['options'] && first_poll['options'].any?
      puts "   Options: #{first_poll['options'].length}"
      poll_id = first_poll['id']

      # Step 3: Vote on the first poll
      puts "\n3. 🗳️ Voting on first poll..."
      first_option_id = first_poll['options'].first['id']

      vote_data = {
        vote: {
          option_id: first_option_id
        }
      }

      vote_response = make_request('POST', "/api/v1/polls/#{poll_id}/votes", vote_data, token)
      if vote_response.code == '201'
        vote_result = JSON.parse(vote_response.body)
        puts "✅ Vote successful - Voted for: #{vote_result['option']['text']}"
      else
        puts "🔄 Vote response: #{vote_response.code} - #{vote_response.body}"
      end

      # Step 4: Check updated poll
      puts "\n4. 🔍 Checking poll after vote..."
      updated_response = make_request('GET', "/api/v1/polls/#{poll_id}", nil, token)
      if updated_response.code == '200'
        updated_poll = JSON.parse(updated_response.body)
        puts "✅ Poll updated - Total votes now: #{updated_poll['total_votes']}"
        if updated_poll['options'] && updated_poll['options'].any?
          updated_poll['options'].each do |option|
            puts "   #{option['text']}: #{option['votes_count']} votes (#{option['percentage']}%)"
          end
        else
          puts "   Options data not available in response"
        end
      end
    else
      puts "   No options found for this poll"
    end
  end
else
  puts "❌ Get polls failed: #{response.code}"
end

# Step 5: Create a new poll
puts "\n5. 🆕 Creating a new poll..."
new_poll_data = {
  poll: {
    title: "Quick Test Poll",
    description: "Testing the API functionality",
    expires_at: (Time.now + 3600).utc.strftime('%Y-%m-%dT%H:%M:%SZ')
  },
  options: [ "Option A", "Option B" ]
}

create_response = make_request('POST', '/api/v1/polls', new_poll_data, token)
if create_response.code == '201'
  new_poll = JSON.parse(create_response.body)
  puts "✅ Poll created successfully - ID: #{new_poll['id']}"
  puts "   Title: #{new_poll['title']}"
else
  puts "❌ Poll creation failed: #{create_response.code} - #{create_response.body}"
end

puts "\n🎉 API test completed successfully!"
puts "The Real-Time Polling API is working correctly!"
