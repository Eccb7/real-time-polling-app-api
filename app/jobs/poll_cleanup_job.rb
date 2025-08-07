class PollCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting poll cleanup job"

    # Deactivate expired polls
    expired_count = Poll.update_expired_polls
    Rails.logger.info "Deactivated #{expired_count} expired polls"

    # Clean up old anonymous vote data (if implemented)
    cleanup_old_data

    # Clear stale cache entries
    clear_stale_cache

    Rails.logger.info "Poll cleanup job completed"
  end

  private

  def cleanup_old_data
    # Remove votes from polls older than 1 year that are inactive
    old_inactive_polls = Poll.where(
      "created_at < ? AND active = ?",
      1.year.ago,
      false
    )

    old_inactive_polls.find_each do |poll|
      poll.votes.delete_all
      poll.options.each { |option| option.update_column(:votes_count, 0) }
    end
  end

  def clear_stale_cache
    # Clear cached poll results for expired polls
    Poll.expired.find_each do |poll|
      Rails.cache.delete("poll_#{poll.id}_expired")
      Rails.cache.delete("poll_#{poll.id}_total_votes")
      Rails.cache.delete_matched("poll_#{poll.id}_results_*")
    end
  end
end
