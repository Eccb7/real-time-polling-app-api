# Configuration for Real-Time Polling App

module PollApp
  class Configuration
    include Singleton

    attr_accessor :rate_limit_enabled,
                  :cache_enabled,
                  :websocket_heartbeat_interval,
                  :poll_cleanup_interval,
                  :max_poll_duration,
                  :max_options_per_poll,
                  :pagination_default_per_page,
                  :pagination_max_per_page

    def initialize
      @rate_limit_enabled = Rails.env.production?
      @cache_enabled = !Rails.env.test?
      @websocket_heartbeat_interval = 30.seconds
      @poll_cleanup_interval = 1.hour
      @max_poll_duration = 30.days
      @max_options_per_poll = 10
      @pagination_default_per_page = 10
      @pagination_max_per_page = 50
    end

    def self.configure
      yield(instance) if block_given?
    end
  end

  def self.config
    Configuration.instance
  end

  # Rate limiting configuration
  RATE_LIMITS = {
    polls: { requests: 5, period: 1.minute },
    votes: { requests: 10, period: 1.minute },
    auth: { requests: 3, period: 1.minute }
  }.freeze

  # Cache expiration times
  CACHE_EXPIRY = {
    poll_results: 30.seconds,
    poll_total_votes: 30.seconds,
    poll_expired: 1.minute,
    user_session: 24.hours
  }.freeze

  # WebSocket configuration
  WEBSOCKET_CONFIG = {
    heartbeat_interval: 30.seconds,
    connection_timeout: 5.minutes,
    max_connections_per_user: 3
  }.freeze
end
