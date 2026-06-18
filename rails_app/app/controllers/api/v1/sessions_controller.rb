# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_user!

      def destroy
        token = extract_token
        if token
          payload = JsonWebToken.decode(token)
          RevokedToken.create!(jti: payload[:jti])
        end
        response.delete_cookie('auth_token', path: '/')
        render json: { message: 'Signed out successfully.' }, status: :ok
      rescue JWT::DecodeError
        render json: { message: 'Signed out.' }, status: :ok
      end
    end
  end
end