class Poll < ApplicationRecord
  belongs_to :user
  has_many :options, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :description, length: { maximum: 1000 }
  validates :expires_at, presence: true
  validate :expires_at_cannot_be_in_the_past

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def total_votes
    votes.count
  end

  def results
    options.includes(:votes).map do |option|
      {
        id: option.id,
        text: option.text,
        votes_count: option.votes.count,
        percentage: total_votes > 0 ? (option.votes.count.to_f / total_votes * 100).round(2) : 0
      }
    end
  end

  private

  def expires_at_cannot_be_in_the_past
    if expires_at.present? && expires_at <= Time.current
      errors.add(:expires_at, "can't be in the past")
    end
  end
end
