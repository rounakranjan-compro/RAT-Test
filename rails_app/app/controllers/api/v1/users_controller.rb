module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def me
        render json: { 
          id: current_user.id, 
          email: current_user.email_id,  # ← fix this
          name: "#{current_user.first_name} #{current_user.last_name}" 
        }
      end
    end
  end
end