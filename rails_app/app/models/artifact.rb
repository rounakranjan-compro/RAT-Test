class Artifact < ApplicationRecord
  belongs_to :test_run

  enum kind: {
    screenshot: 'screenshot',
    video: 'video',
    trace: 'trace',
    error_log: 'error_log'
  }

  validates :kind, presence: true
  validates :file_url, presence: true, unless: :error_log?
end

