# app/controllers/api/v1/omniauth_callbacks_controller.rb
class Api::V1::OmniauthCallbacksController < ApplicationController
  skip_before_action :authenticate_user!

  def google_oauth2
    Rails.logger.info "FRONTEND_URL: #{ENV['FRONTEND_URL']}"
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user.persisted?
      token = JsonWebToken.encode(sub: user.id)
      response.set_cookie('auth_token', {
        value:     token,
        httponly:  true,
        secure:    Rails.env.production?,
        same_site: :lax,
        expires:   24.hours.from_now,
        path:      '/'
      })
      redirect_to "#{ENV['FRONTEND_URL']}/auth/callback",
                  allow_other_host: true
    else
      redirect_to "#{ENV['FRONTEND_URL']}/login?error=google_failed",
                  allow_other_host: true
    end
  end

  def failure
    redirect_to "#{ENV['FRONTEND_URL']}/login?error=google_failed",
                allow_other_host: true
  end
end