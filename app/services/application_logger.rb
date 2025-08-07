class ApplicationLogger
  include Singleton

  def self.log_event(event_type, data = {})
    instance.log_event(event_type, data)
  end

  def log_event(event_type, data = {})
    log_data = {
      event: event_type,
      timestamp: Time.current.iso8601,
      data: data
    }

    case event_type
    when :user_registration
      Rails.logger.info("User Registration: #{data[:user_email]}")
    when :poll_created
      Rails.logger.info("Poll Created: #{data[:poll_title]} by #{data[:user_email]}")
    when :vote_cast
      Rails.logger.info("Vote Cast: Poll #{data[:poll_id]} by #{data[:user_email]}")
    when :websocket_connection
      Rails.logger.info("WebSocket Connection: User #{data[:user_id]}")
    when :rate_limit_exceeded
      Rails.logger.warn("Rate Limit Exceeded: #{data[:controller]} by #{data[:identifier]}")
    when :security_violation
      Rails.logger.error("Security Violation: #{data[:violation_type]} - #{data[:details]}")
    else
      Rails.logger.info("Event: #{event_type} - #{log_data.to_json}")
    end

    # Send to external monitoring service in production
    if Rails.env.production?
      send_to_monitoring_service(log_data)
    end
  end

  private

  def send_to_monitoring_service(data)
    # Integration with services like Datadog, New Relic, etc.
    # Example: NewRelic::Agent.record_custom_event('AppEvent', data)
  end
end
