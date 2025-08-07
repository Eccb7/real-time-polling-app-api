class Poll < ApplicationRecord
  belongs_to :user
  has_many :options, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :description, length: { maximum: 1000 }
  validates :expires_at, presence: true
  validate :expires_at_cannot_be_in_the_past
  validate :minimum_options_count, on: :create

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { joins(:votes).group("polls.id").order("COUNT(votes.id) DESC") }

  # Caching for expensive operations
  def expired?
    Rails.cache.fetch("poll_#{id}_expired", expires_in: 1.minute) do
      expires_at <= Time.current
    end
  end

  def total_votes
    Rails.cache.fetch("poll_#{id}_total_votes", expires_in: 30.seconds) do
      votes.count
    end
  end

  def results_with_caching
    Rails.cache.fetch("poll_#{id}_results_#{votes.maximum(:updated_at)}", expires_in: 30.seconds) do
      calculate_results
    end
  end

  def results
    calculate_results
  end

  # Optimized method to get poll with all related data
  def self.with_full_data
    includes(
      :user,
      options: :votes,
      votes: :user
    )
  end

  # Bulk operations for better performance
  def self.update_expired_polls
    where("expires_at <= ? AND active = ?", Time.current, true)
      .update_all(active: false, updated_at: Time.current)
  end

  def increment_view_count!
    Rails.cache.increment("poll_#{id}_views", 1)
  end

  def view_count
    Rails.cache.fetch("poll_#{id}_views") { 0 }
  end

  private

  def calculate_results
    total = total_votes
    options.includes(:votes).map do |option|
      vote_count = option.votes.size
      {
        id: option.id,
        text: option.text,
        votes_count: vote_count,
        percentage: total > 0 ? (vote_count.to_f / total * 100).round(2) : 0
      }
    end
  end

  def expires_at_cannot_be_in_the_past
    if expires_at.present? && expires_at <= Time.current
      errors.add(:expires_at, "can't be in the past")
    end
  end

  def minimum_options_count
    if options.size < 2
      errors.add(:options, "must have at least 2 options")
    end
  end

  # Clear cache when poll is updated
  after_update :clear_cache
  after_destroy :clear_cache

  def clear_cache
    Rails.cache.delete("poll_#{id}_expired")
    Rails.cache.delete("poll_#{id}_total_votes")
    Rails.cache.delete_matched("poll_#{id}_results_*")
  end
end
