# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = extract_token
    return render json: { error: 'Missing token' }, status: :unauthorized unless token

    begin
      payload = JsonWebToken.decode(token)

      # Check denylist
      if RevokedToken.exists?(jti: payload[:jti])
        return render json: { error: 'Token has been revoked' }, status: :unauthorized
      end

      @current_user = User.find(payload[:sub])
    rescue JWT::ExpiredSignature
      render json: { error: 'Token expired' }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: 'Invalid token' }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def extract_token
  # try cookie first, then Authorization header
  request.cookies['auth_token'] || request.headers['Authorization']&.split(' ')&.last
  end
end