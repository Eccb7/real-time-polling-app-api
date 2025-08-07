# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample users
puts "Creating sample users..."

user1 = User.find_or_create_by!(email: 'alice@example.com') do |user|
  user.name = 'Alice Johnson'
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

user2 = User.find_or_create_by!(email: 'bob@example.com') do |user|
  user.name = 'Bob Smith'
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

user3 = User.find_or_create_by!(email: 'charlie@example.com') do |user|
  user.name = 'Charlie Brown'
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

puts "Created #{User.count} users"

# Create sample polls
puts "Creating sample polls..."

# Poll 1: Programming languages
poll1 = Poll.find_or_create_by!(title: 'What is your favorite programming language?') do |poll|
  poll.description = 'Help us understand the most popular programming languages among developers'
  poll.user = user1
  poll.active = true
  poll.expires_at = 1.week.from_now
end

if poll1.options.empty?
  poll1.options.create!([
    { text: 'JavaScript' },
    { text: 'Python' },
    { text: 'Ruby' },
    { text: 'Java' },
    { text: 'TypeScript' },
    { text: 'Go' }
  ])
end

# Poll 2: Remote work preference
poll2 = Poll.find_or_create_by!(title: 'What is your preferred work arrangement?') do |poll|
  poll.description = 'Understanding modern work preferences in the tech industry'
  poll.user = user2
  poll.active = true
  poll.expires_at = 2.weeks.from_now
end

if poll2.options.empty?
  poll2.options.create!([
    { text: 'Fully remote' },
    { text: 'Hybrid (2-3 days in office)' },
    { text: 'Fully in-office' },
    { text: 'Flexible/No preference' }
  ])
end

# Poll 3: Best framework
poll3 = Poll.find_or_create_by!(title: 'Best web framework for 2025?') do |poll|
  poll.description = 'What web framework do you think will dominate in 2025?'
  poll.user = user3
  poll.active = true
  poll.expires_at = 10.days.from_now
end

if poll3.options.empty?
  poll3.options.create!([
    { text: 'React' },
    { text: 'Vue.js' },
    { text: 'Angular' },
    { text: 'Svelte' },
    { text: 'Next.js' },
    { text: 'Nuxt.js' }
  ])
end

puts "Created #{Poll.count} polls with #{Option.count} total options"

# Create some sample votes
puts "Creating sample votes..."

# Add some votes to poll1 (Programming languages)
poll1_options = poll1.options.to_a
Vote.find_or_create_by!(user: user2, poll: poll1, option: poll1_options[1]) # Python
Vote.find_or_create_by!(user: user3, poll: poll1, option: poll1_options[0]) # JavaScript

# Add some votes to poll2 (Remote work)
poll2_options = poll2.options.to_a
Vote.find_or_create_by!(user: user1, poll: poll2, option: poll2_options[0]) # Fully remote
Vote.find_or_create_by!(user: user3, poll: poll2, option: poll2_options[1]) # Hybrid

# Add some votes to poll3 (Frameworks)
poll3_options = poll3.options.to_a
Vote.find_or_create_by!(user: user1, poll: poll3, option: poll3_options[0]) # React
Vote.find_or_create_by!(user: user2, poll: poll3, option: poll3_options[4]) # Next.js

# Update vote counts
Poll.all.each do |poll|
  poll.options.each do |option|
    option.update_column(:votes_count, option.votes.count)
  end
end

puts "Created #{Vote.count} votes"
puts "Seed data created successfully!"

puts "\nSample users created:"
puts "- alice@example.com (password: password123)"
puts "- bob@example.com (password: password123)"
puts "- charlie@example.com (password: password123)"
