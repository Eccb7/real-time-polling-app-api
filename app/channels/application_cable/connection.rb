module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Try to get token from query parameters (for WebSocket connections)
      token = request.params[:token]

      # If no token in params, try to get from headers
      token ||= request.headers["Authorization"]&.split(" ")&.last

      if token
        begin
          decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" })
          user_id = decoded_token.first["user_id"]
          user = User.find(user_id)
          user
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          reject_unauthorized_connection
        end
      else
        reject_unauthorized_connection
      end
    end
  end
end
