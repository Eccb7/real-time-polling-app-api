class ApplicationController < ActionController::API
  include ActionController::Cookies
  include RateLimitable

  before_action :authenticate_user
  before_action :set_current_user_for_logs

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from JWT::DecodeError, with: :invalid_token
  rescue_from StandardError, with: :internal_server_error

  private

  def authenticate_user
    token = extract_token_from_header
    return render_unauthorized("No token provided") unless token

    begin
      decoded_token = JWT.decode(token, jwt_secret, true, { algorithm: "HS256" })
      payload = decoded_token.first

      # Check token expiration
      if payload["exp"] && Time.at(payload["exp"]) < Time.current
        return render_unauthorized("Token expired")
      end

      @current_user = User.find(payload["user_id"])

    rescue JWT::ExpiredSignature
      render_unauthorized("Token expired")
    rescue JWT::DecodeError
      render_unauthorized("Invalid token")
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("User not found")
    end
  end

  def current_user
    @current_user
  end

  def generate_token(user)
    payload = {
      user_id: user.id,
      exp: token_expiration_time.to_i,
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }
    JWT.encode(payload, jwt_secret, "HS256")
  end

  def skip_authentication
    skip_before_action :authenticate_user
  end

  # Error handling methods
  def record_not_found(error)
    render json: {
      error: "Resource not found",
      details: error.message
    }, status: :not_found
  end

  def record_invalid(error)
    render json: {
      error: "Validation failed",
      details: error.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def invalid_token(error)
    render_unauthorized("Invalid token format")
  end

  def internal_server_error(error)
    Rails.logger.error "Internal Server Error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    render json: {
      error: "Internal server error",
      message: Rails.env.development? ? error.message : "Something went wrong"
    }, status: :internal_server_error
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    auth_header&.split(" ")&.last if auth_header&.start_with?("Bearer ")
  end

  def jwt_secret
    Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
  end

  def token_expiration_time
    24.hours.from_now
  end

  def set_current_user_for_logs
    if current_user
      Rails.logger.tagged("user_id:#{current_user.id}") do
        yield if block_given?
      end
    end
  end
end
