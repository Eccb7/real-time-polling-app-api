class PollSerializer
  include Alba::Resource

  attributes :id, :title, :description, :active, :expires_at, :created_at, :updated_at

  attribute :expired do |poll|
    poll.expired?
  end

  attribute :total_votes do |poll|
    poll.total_votes
  end

  attribute :view_count do |poll|
    poll.view_count
  end

  one :user, serializer: UserSerializer
  many :options, serializer: OptionSerializer

  attribute :results do |poll|
    poll.results
  end
end

class UserSerializer
  include Alba::Resource

  attributes :id, :name, :created_at

  # Don't expose email in public API responses
  attribute :email, if: proc { |user, params|
    params&.dig(:current_user)&.id == user.id
  }
end

class OptionSerializer
  include Alba::Resource

  attributes :id, :text, :votes_count

  attribute :percentage do |option|
    option.vote_percentage
  end
end

class VoteSerializer
  include Alba::Resource

  attributes :id, :created_at

  one :user, serializer: UserSerializer
  one :option, serializer: OptionSerializer
  one :poll, serializer: PollSerializer
end
