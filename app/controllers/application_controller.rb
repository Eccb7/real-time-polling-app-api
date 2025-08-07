class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_user

  private

  def authenticate_user
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "No token provided" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" })
      user_id = decoded_token.first["user_id"]
      @current_user = User.find(user_id)
    rescue JWT::DecodeError
      render json: { error: "Invalid token" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def generate_token(user)
    payload = {
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, "HS256")
  end

  def skip_authentication
    skip_before_action :authenticate_user
  end
end
