class HealthController < ActionController::API
  def check
    render json: { 
      status: 'ok', 
      timestamp: Time.current,
      database: database_connected?
    }
  end

  private

  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue
    false
  end
end
