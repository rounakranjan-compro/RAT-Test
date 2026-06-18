class Feature < ApplicationRecord
  belongs_to :user
  has_many :tests, dependent: :destroy
  validates :name, presence: true, uniqueness: { scope: :user_id }

  def run_all_tests_sequentially
    tests.each do |test|
      # trigger test run
    end
  end
end