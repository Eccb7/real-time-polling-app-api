class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :option
  belongs_to :poll
  
  validates :user_id, uniqueness: { scope: :poll_id, message: "can only vote once per poll" }
  validate :option_belongs_to_poll
  validate :poll_is_active_and_not_expired
  
  after_create :update_option_votes_count
  after_destroy :update_option_votes_count
  
  private
  
  def option_belongs_to_poll
    if option && poll && option.poll_id != poll.id
      errors.add(:option, "must belong to the poll")
    end
  end
  
  def poll_is_active_and_not_expired
    if poll && (!poll.active? || poll.expired?)
      errors.add(:poll, "is not active or has expired")
    end
  end
  
  def update_option_votes_count
    option.update_column(:votes_count, option.votes.count)
  end
end
