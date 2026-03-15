class SubmissionRecord < ApplicationRecord
  RECORD_TYPES = %w[hyperlink file].freeze

  validates :record_type, presence: true, inclusion: { in: RECORD_TYPES }
  validates :content, presence: true
  validates :operation, presence: true
  validates :team_id, presence: true
  validates :user, presence: true
  validates :assignment_id, presence: true

  scope :files, -> { where(record_type: 'file') }
  scope :hyperlinks, -> { where(record_type: 'hyperlink') }

  def file?
    record_type == 'file'
  end

  def hyperlink?
    record_type == 'hyperlink'
  end
end
