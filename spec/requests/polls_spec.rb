require 'rails_helper'

RSpec.describe 'Polls API', type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{generate_token(user)}" } }

  describe 'GET /api/v1/polls' do
    before do
      create_list(:poll, 3, :with_options, user: user)
    end

    it 'returns paginated polls' do
      get '/api/v1/polls', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['polls']).to be_an(Array)
      expect(json_response['pagination']).to be_present
    end

    it 'supports sorting by popularity' do
      get '/api/v1/polls?sort=popular', headers: auth_headers

      expect(response).to have_http_status(:ok)
    end

    it 'supports pagination' do
      get '/api/v1/polls?page=1&per_page=2', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['polls'].length).to eq(2)
    end
  end

  describe 'POST /api/v1/polls' do
    let(:poll_params) do
      {
        poll: {
          title: 'Test Poll',
          description: 'Test Description',
          expires_at: 1.week.from_now
        },
        options: [ 'Option 1', 'Option 2', 'Option 3' ]
      }
    end

    it 'creates a poll with options' do
      expect {
        post '/api/v1/polls', params: poll_params, headers: auth_headers
      }.to change(Poll, :count).by(1)
        .and change(Option, :count).by(3)

      expect(response).to have_http_status(:created)
      expect(json_response['poll']['title']).to eq('Test Poll')
    end

    it 'validates required fields' do
      post '/api/v1/polls', params: { poll: { title: '' } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'PUT /api/v1/polls/:id' do
    let(:poll) { create(:poll, user: user) }

    it 'updates poll when user is owner' do
      put "/api/v1/polls/#{poll.id}",
          params: { poll: { title: 'Updated Title' } },
          headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(poll.reload.title).to eq('Updated Title')
    end

    it 'denies access when user is not owner' do
      other_user = create(:user)
      other_poll = create(:poll, user: other_user)

      put "/api/v1/polls/#{other_poll.id}",
          params: { poll: { title: 'Hacked' } },
          headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end

  def generate_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end
end
