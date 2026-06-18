class Test < ApplicationRecord
  belongs_to :user
  belongs_to :feature, optional: true
  belongs_to :script, dependent: :destroy
  has_many :test_runs, dependent: :destroy
  validates :title, presence: true

  def tags_list
    return [] if tags.blank?
    tags.split(',').map(&:strip).reject(&:blank?)
  end
end