class Option < ApplicationRecord
  belongs_to :poll
  has_many :votes, dependent: :destroy

  validates :text, presence: true, length: { minimum: 1, maximum: 100 }
  validates :votes_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_default_votes_count, on: :create

  def vote_percentage
    total_votes = poll.total_votes
    return 0 if total_votes.zero?

    (votes.count.to_f / total_votes * 100).round(2)
  end

  private

  def set_default_votes_count
    self.votes_count ||= 0
  end
end
