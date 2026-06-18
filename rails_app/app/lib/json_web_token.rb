module JsonWebToken
  SECRET = ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base
  EXPIRY = 24.hours.to_i

  def self.encode(payload)
    payload[:exp] = Time.now.to_i + EXPIRY
    payload[:jti] = SecureRandom.uuid
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: 'HS256')
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise e
  end
end
