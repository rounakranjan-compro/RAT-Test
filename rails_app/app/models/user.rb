class User < ApplicationRecord
  has_many :features, dependent: :destroy
  has_many :tests, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email_id           = auth.info.email
      user.first_name         = auth.info.first_name
      user.last_name          = auth.info.last_name
      user.encrypted_password = SecureRandom.hex(32)
    end
  end
end