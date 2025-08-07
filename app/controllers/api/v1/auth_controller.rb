class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user, only: [ :register, :login ]

  def register
    user = User.new(user_params)

    if user.save
      token = generate_token(user)
      render json: {
        message: "User created successfully",
        user: user_response(user),
        token: token
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      token = generate_token(user)
      render json: {
        message: "Login successful",
        user: user_response(user),
        token: token
      }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def me
    render json: { user: user_response(current_user) }
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at
    }
  end
end
