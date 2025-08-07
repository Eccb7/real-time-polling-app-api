#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class APITester
  BASE_URL = 'http://localhost:3000'

  def initialize
    @tokens = {}
  end

  def run_tests
    puts "🚀 Starting API Tests for Real-Time Polling App"
    puts "=" * 50

    # Test 1: User Registration
    test_user_registration

    # Test 2: User Login
    test_user_login

    # Test 3: Get Current User
    test_get_current_user

    # Test 4: Get All Polls
    test_get_all_polls

    # Test 5: Create New Poll
    test_create_poll

    # Test 6: Get Specific Poll
    test_get_specific_poll

    # Test 7: Vote on Poll
    test_vote_on_poll

    # Test 8: Get User's Own Polls
    test_get_my_polls

    # Test 9: Authentication Errors
    test_authentication_errors

    puts "\n🎉 All API tests completed!"
    puts "Check the output above for any failures."
  end

  private

  def test_user_registration
    puts "\n📝 Testing User Registration..."

    data = {
      user: {
        name: "API Test User",
        email: "apitest#{Time.now.to_i}@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    response = make_request('POST', '/api/v1/auth/register', data)

    if response.code == '201'
      result = JSON.parse(response.body)
      puts "✅ Registration successful"
      puts "   User ID: #{result['user']['id']}"
      puts "   Name: #{result['user']['name']}"
      puts "   Email: #{result['user']['email']}"
      @tokens[:test_user] = result['token']
    else
      puts "❌ Registration failed: #{response.code} - #{response.body}"
    end
  end

  def test_user_login
    puts "\n🔐 Testing User Login (existing user)..."

    data = {
      email: "alice@example.com",
      password: "password123"
    }

    response = make_request('POST', '/api/v1/auth/login', data)

    if response.code == '200'
      result = JSON.parse(response.body)
      puts "✅ Login successful"
      puts "   User: #{result['user']['name']}"
      puts "   Token: #{result['token'][0..20]}..."
      @tokens[:alice] = result['token']
    else
      puts "❌ Login failed: #{response.code} - #{response.body}"
    end
  end

  def test_get_current_user
    puts "\n👤 Testing Get Current User..."

    response = make_authenticated_request('GET', '/api/v1/auth/me', nil, @tokens[:alice])

    if response.code == '200'
      result = JSON.parse(response.body)
      puts "✅ Get current user successful"
      puts "   Name: #{result['name']}"
      puts "   Email: #{result['email']}"
    else
      puts "❌ Get current user failed: #{response.code} - #{response.body}"
    end
  end

  def test_get_all_polls
    puts "\n📊 Testing Get All Polls..."

    response = make_authenticated_request('GET', '/api/v1/polls', nil, @tokens[:alice])

    if response.code == '200'
      result = JSON.parse(response.body)
      polls = result['polls'] || result
      puts "✅ Get polls successful"
      puts "   Found #{polls.length} active polls"
      polls.each_with_index do |poll, index|
        options_count = poll['options']&.length || 0
        total_votes = poll['total_votes'] || 0
        puts "   #{index + 1}. #{poll['title']} (#{options_count} options, #{total_votes} votes)"
      end
    else
      puts "❌ Get polls failed: #{response.code} - #{response.body}"
    end
  end

  def test_create_poll
    puts "\n🆕 Testing Create New Poll..."

    data = {
      poll: {
        title: "Best Ruby Framework?",
        description: "Choose your favorite Ruby web framework",
        expires_at: (Time.now + 24 * 3600).utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      },
      options: [ "Ruby on Rails", "Sinatra", "Hanami", "Roda" ]
    }

    response = make_authenticated_request('POST', '/api/v1/polls', data, @tokens[:alice])

    if response.code == '201'
      result = JSON.parse(response.body)
      puts "✅ Poll creation successful"
      puts "   Poll ID: #{result['id']}"
      puts "   Title: #{result['title']}"
      options = result['options'] || []
      puts "   Options: #{options.map { |o| o['text'] }.join(', ')}" if options.any?
      @created_poll_id = result['id']
    else
      puts "❌ Poll creation failed: #{response.code} - #{response.body}"
    end
  end

  def test_get_specific_poll
    return unless @created_poll_id

    puts "\n🔍 Testing Get Specific Poll..."

    response = make_authenticated_request('GET', "/api/v1/polls/#{@created_poll_id}", nil, @tokens[:alice])

    if response.code == '200'
      result = JSON.parse(response.body)
      puts "✅ Get specific poll successful"
      puts "   Title: #{result['title']}"
      puts "   Total Votes: #{result['total_votes']}"
      puts "   Options:"
      result['options'].each do |option|
        puts "     - #{option['text']}: #{option['votes_count']} votes (#{option['percentage']}%)"
      end
    else
      puts "❌ Get specific poll failed: #{response.code} - #{response.body}"
    end
  end

  def test_vote_on_poll
    return unless @created_poll_id

    puts "\n🗳️ Testing Vote on Poll..."

    # First get the poll to find option IDs
    response = make_authenticated_request('GET', "/api/v1/polls/#{@created_poll_id}", nil, @tokens[:alice])
    if response.code == '200'
      poll = JSON.parse(response.body)
      first_option_id = poll['options'].first['id']

      data = {
        vote: {
          option_id: first_option_id
        }
      }

      vote_response = make_authenticated_request('POST', "/api/v1/polls/#{@created_poll_id}/votes", data, @tokens[:alice])

      if vote_response.code == '201'
        result = JSON.parse(vote_response.body)
        puts "✅ Vote successful"
        puts "   Voted for: #{result['option']['text']}"
        puts "   Vote ID: #{result['id']}"
        @vote_id = result['id']
      else
        puts "❌ Vote failed: #{vote_response.code} - #{vote_response.body}"
      end
    else
      puts "❌ Could not get poll for voting: #{response.code}"
    end
  end

  def test_get_my_polls
    puts "\n📋 Testing Get My Polls..."

    response = make_authenticated_request('GET', '/api/v1/polls/my_polls', nil, @tokens[:alice])

    if response.code == '200'
      result = JSON.parse(response.body)
      polls = result['polls'] || result
      puts "✅ Get my polls successful"
      puts "   Found #{polls.length} polls created by user"
      polls.each_with_index do |poll, index|
        puts "   #{index + 1}. #{poll['title']} (#{poll['total_votes']} total votes)"
      end
    else
      puts "❌ Get my polls failed: #{response.code} - #{response.body}"
    end
  end

  def test_authentication_errors
    puts "\n🔒 Testing Authentication Errors..."

    # Test without token
    response = make_request('GET', '/api/v1/polls')
    if response.code == '401'
      puts "✅ Correctly rejected request without authentication"
    else
      puts "❌ Should have rejected request without auth: #{response.code}"
    end

    # Test with invalid token
    response = make_authenticated_request('GET', '/api/v1/polls', nil, 'invalid.token.here')
    if response.code == '401'
      puts "✅ Correctly rejected request with invalid token"
    else
      puts "❌ Should have rejected request with invalid token: #{response.code}"
    end
  end

  def make_request(method, path, data = nil)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    case method
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
    when 'PUT'
      request = Net::HTTP::Put.new(uri)
    when 'DELETE'
      request = Net::HTTP::Delete.new(uri)
    end

    request['Content-Type'] = 'application/json'
    request.body = data.to_json if data

    http.request(request)
  end

  def make_authenticated_request(method, path, data = nil, token = nil)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)

    case method
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
    when 'PUT'
      request = Net::HTTP::Put.new(uri)
    when 'DELETE'
      request = Net::HTTP::Delete.new(uri)
    end

    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{token}" if token
    request.body = data.to_json if data

    http.request(request)
  end
end

# Run the tests
tester = APITester.new
tester.run_tests
