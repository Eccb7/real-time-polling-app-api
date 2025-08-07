module RateLimitable
  extend ActiveSupport::Concern

  included do
    before_action :check_rate_limit, only: [ :create, :update ]
  end

  private

  def check_rate_limit
    key = "rate_limit:#{controller_name}:#{current_user&.id || request.remote_ip}"

    current_requests = Rails.cache.fetch(key, expires_in: 1.minute) { 0 }

    if current_requests >= rate_limit_threshold
      render json: {
        error: "Rate limit exceeded. Please try again later.",
        retry_after: 60
      }, status: :too_many_requests
      return
    end

    Rails.cache.write(key, current_requests + 1, expires_in: 1.minute)
  end

  def rate_limit_threshold
    case controller_name
    when "polls"
      5  # 5 polls per minute
    when "votes"
      10 # 10 votes per minute
    when "auth"
      3  # 3 auth attempts per minute
    else
      10
    end
  end
end
