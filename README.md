# Real-Time Polling App API

A Ruby on Rails API backend for a real-time polling application with WebSocket support using Action Cable. This application allows users to create polls, vote on them, and see real-time updates without page refreshes.

## Features

- **User Authentication**: JWT-based authentication system
- **Poll Management**: Create, read, update, and delete polls
- **Real-time Voting**: Vote on polls with real-time updates
- **WebSocket Communication**: Live updates using Action Cable
- **PostgreSQL Database**: Robust data storage with proper relationships
- **RESTful API**: Well-structured API endpoints
- **CORS Support**: Cross-origin resource sharing enabled

## Tech Stack

- **Ruby on Rails 8.0** - API-only mode
- **PostgreSQL** - Primary database
- **Action Cable** - WebSocket functionality
- **JWT** - Authentication tokens
- **BCrypt** - Password hashing
- **Rack-CORS** - Cross-origin support

## Getting Started

### Prerequisites

- Ruby 3.3.0+
- Rails 8.0+
- PostgreSQL
- Bundler

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Eccb7/real-time-polling-app-api.git
cd real-time-polling-app-api
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Start the server:
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register a new user |
| POST | `/api/v1/auth/login` | Login user |
| GET | `/api/v1/auth/me` | Get current user info |

### Polls

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/polls` | Get all active polls |
| GET | `/api/v1/polls/:id` | Get specific poll |
| POST | `/api/v1/polls` | Create a new poll |
| PUT | `/api/v1/polls/:id` | Update poll (owner only) |
| DELETE | `/api/v1/polls/:id` | Delete poll (owner only) |
| GET | `/api/v1/polls/my_polls` | Get user's own polls |

### Votes

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/polls/:poll_id/votes` | Cast a vote |
| DELETE | `/api/v1/votes/:id` | Remove a vote |

## Request/Response Examples

### User Registration
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Doe",
      "email": "john@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### User Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Create Poll
```bash
curl -X POST http://localhost:3000/api/v1/polls \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "poll": {
      "title": "What is your favorite programming language?",
      "description": "Choose your preferred programming language",
      "expires_at": "2025-08-14T14:00:00Z"
    },
    "options": ["JavaScript", "Python", "Ruby", "Java"]
  }'
```

### Cast Vote
```bash
curl -X POST http://localhost:3000/api/v1/polls/1/votes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "vote": {
      "option_id": 1
    }
  }'
```

## WebSocket Integration

### Action Cable Connection

Connect to the WebSocket server at: `ws://localhost:3000/cable`

Include the JWT token as a query parameter:
```
ws://localhost:3000/cable?token=YOUR_JWT_TOKEN
```

### Subscribing to Channels

#### General Polls Channel
```javascript
// Subscribe to all poll updates
consumer.subscriptions.create("PollsChannel", {
  received(data) {
    console.log("Poll update:", data);
    // Handle poll creation, updates, or deletion
  }
});
```

#### Specific Poll Channel
```javascript
// Subscribe to a specific poll's updates
consumer.subscriptions.create({ channel: "PollsChannel", poll_id: 1 }, {
  received(data) {
    console.log("Poll 1 update:", data);
    // Handle real-time voting updates
  }
});
```

### WebSocket Message Types

- `poll_created`: New poll created
- `poll_updated`: Poll information updated
- `poll_deleted`: Poll deleted
- `vote_cast`: New vote received
- `vote_removed`: Vote removed

## Database Schema

### Users
- `id` (Primary Key)
- `name` (String, required)
- `email` (String, required, unique)
- `password_digest` (String, required)
- `created_at`, `updated_at`

### Polls
- `id` (Primary Key)
- `title` (String, required)
- `description` (Text, optional)
- `user_id` (Foreign Key)
- `active` (Boolean, default: true)
- `expires_at` (DateTime, required)
- `created_at`, `updated_at`

### Options
- `id` (Primary Key)
- `text` (String, required)
- `poll_id` (Foreign Key)
- `votes_count` (Integer, default: 0)
- `created_at`, `updated_at`

### Votes
- `id` (Primary Key)
- `user_id` (Foreign Key)
- `poll_id` (Foreign Key)
- `option_id` (Foreign Key)
- `created_at`, `updated_at`
- Unique constraint on `user_id` + `poll_id` (one vote per user per poll)

## Key Learning Points Implemented

### 1. Action Cable for Real-time Features
- WebSocket connection with JWT authentication
- Broadcasting poll updates to all connected clients
- Real-time vote counting and results display

### 2. WebSocket Connection Setup
- Custom Action Cable connection class with authentication
- Channel subscriptions for both general and specific poll updates
- Proper error handling for unauthorized connections

### 3. Broadcasting Data to Connected Clients
- Automatic broadcasting when polls are created, updated, or deleted
- Real-time vote updates broadcast to all subscribers
- Structured message format for different event types

### 4. Poll and Option Models
- Comprehensive relationships between User, Poll, Option, and Vote models
- Business logic for vote counting and percentage calculations
- Proper validations and constraints

### 5. Real-time Poll Results
- Live updating of vote counts and percentages
- Instant feedback when votes are cast or removed
- Historical data preservation

## Advanced Features

### User Authentication
- JWT token-based authentication
- Secure password hashing with BCrypt
- Token expiration and validation

### Poll Management
- Poll expiration handling
- Owner-only edit/delete permissions
- Active/inactive poll states

### Voting System
- One vote per user per poll constraint
- Vote changing capabilities (remove and re-vote)
- Real-time vote count updates

## Testing

Run the test suite:
```bash
rails test
```

## Sample Users

The application comes with pre-seeded sample users:
- **Alice Johnson**: `alice@example.com` (password: `password123`)
- **Bob Smith**: `bob@example.com` (password: `password123`)
- **Charlie Brown**: `charlie@example.com` (password: `password123`)

## Frontend Integration

This API is designed to work with any frontend framework. For real-time features, the frontend should:

1. Establish WebSocket connection with JWT token
2. Subscribe to appropriate Action Cable channels
3. Handle incoming WebSocket messages for live updates
4. Use standard HTTP requests for CRUD operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
