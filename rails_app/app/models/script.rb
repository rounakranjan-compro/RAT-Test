# app/models/script.rb
class Script < ApplicationRecord
  has_one :test

  validates :name, presence: true
  validates :language, inclusion: { in: %w[javascript typescript] }
end

