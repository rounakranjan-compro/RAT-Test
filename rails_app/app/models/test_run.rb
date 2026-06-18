class TestRun < ApplicationRecord
  belongs_to :test
  belongs_to :script
  has_many :artifacts, dependent: :destroy

  serialize :tags, Array

  ENVIRONMENTS = %w[QA DEV].freeze
  RUNNER_MODES = %w[headless headed].freeze
  MAX_RETRIES  = 4

  enum status: {
    queued:  "queued",
    running: "running",
    passed:  "passed",
    failed:  "failed"
  }

  validates :environment,
            presence: true,
            inclusion: { in: ENVIRONMENTS }

  validates :runner_mode,
            presence: true,
            inclusion: { in: RUNNER_MODES }

  validates :retries_on_failure,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_RETRIES
            }

  validates :status, presence: true

  validates :tags, length: { maximum: 10 }, allow_nil: true

  before_validation :set_defaults

  private

  def set_defaults
    self.runner_mode ||= "headless"
    self.retries_on_failure ||= 0
    self.tags ||= []
    self.status ||= "not_run"
  end
end