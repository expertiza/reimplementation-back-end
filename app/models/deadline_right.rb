# frozen_string_literal: true

class DeadlineRight < ApplicationRecord
  # Constants for deadline right IDs
  NO = 1
  LATE = 2
  OK = 3

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  # Scopes for different permission levels
  scope :allowing, -> { where(name: %w[OK Late]) }
  scope :denying, -> { where(name: 'No') }
  scope :with_penalty, -> { where(name: 'Late') }
  scope :without_penalty, -> { where(name: 'OK') }

  # Class methods for finding deadline rights
  def self.find_by_name(name)
    find_by(name: name.to_s)
  end

  def self.no
    find_by_name('No')
  end

  def self.late
    find_by_name('Late')
  end

  def self.ok
    find_by_name('OK')
  end

  # Permission checking methods
  def allows_action?
    %w[OK Late].include?(name)
  end

  def denies_action?
    name == 'No'
  end

  def allows_with_penalty?
    name == 'Late'
  end

  def allows_without_penalty?
    name == 'OK'
  end

  # Semantic helper methods
  def no?
    name == 'No'
  end

  def late?
    name == 'Late'
  end

  def ok?
    name == 'OK'
  end

  # Display methods
  def display_name
    name
  end

  def display_description
    description
  end

  def to_s
    name
  end

  def css_class
    case name
    when 'OK'
      'deadline-allowed'
    when 'Late'
      'deadline-late'
    when 'No'
      'deadline-denied'
    else
      'deadline-unknown'
    end
  end

  def icon
    case name
    when 'OK'
      'check-circle'
    when 'Late'
      'clock'
    when 'No'
      'x-circle'
    else
      'question-circle'
    end
  end

  # Method to get human-readable status with context
  def status_with_context(action)
    case name
    when 'OK'
      "#{action.to_s.humanize} is allowed"
    when 'Late'
      "#{action.to_s.humanize} is allowed with late penalty"
    when 'No'
      "#{action.to_s.humanize} is not allowed"
    else
      "#{action.to_s.humanize} status unknown"
    end
  end

  # Comparison methods
  def more_permissive_than?(other)
    return false unless other.is_a?(DeadlineRight)

    permission_level > other.permission_level
  end

  def less_permissive_than?(other)
    return false unless other.is_a?(DeadlineRight)

    permission_level < other.permission_level
  end

  def permission_level
    case name
    when 'No'
      0
    when 'Late'
      1
    when 'OK'
      2
    else
      -1
    end
  end

  def <=>(other)
    return nil unless other.is_a?(DeadlineRight)

    permission_level <=> other.permission_level
  end

  # Method to seed the deadline rights (for use in migrations/seeds)
  def self.seed_deadline_rights!
    deadline_rights = [
      { id: NO, name: 'No', description: 'Action is not allowed' },
      { id: LATE, name: 'Late', description: 'Action is allowed with late penalty' },
      { id: OK, name: 'OK', description: 'Action is allowed without penalty' }
    ]

    deadline_rights.each do |right_attrs|
      find_or_create_by(id: right_attrs[:id]) do |dr|
        dr.name = right_attrs[:name]
        dr.description = right_attrs[:description]
      end
    end
  end

  # Validation methods
  def self.valid_right_names
    %w[No Late OK]
  end

  def self.validate_right_name(name)
    valid_right_names.include?(name.to_s)
  end

  # Statistics methods
  def usage_count
    # Count how many due_dates reference this deadline right
    # This is a general count across all permission fields
    count = 0

    # Check submission permissions
    count += DueDate.where(submission_allowed_id: id).count

    # Check review permissions
    count += DueDate.where(review_allowed_id: id).count

    # Check quiz permissions
    count += DueDate.where(quiz_allowed_id: id).count

    # Check teammate review permissions
    count += DueDate.where(teammate_review_allowed_id: id).count

    # Check other permission fields if they exist
    if DueDate.column_names.include?('resubmission_allowed_id')
      count += DueDate.where(resubmission_allowed_id: id).count
    end

    if DueDate.column_names.include?('rereview_allowed_id')
      count += DueDate.where(rereview_allowed_id: id).count
    end

    if DueDate.column_names.include?('review_of_review_allowed_id')
      count += DueDate.where(review_of_review_allowed_id: id).count
    end

    count
  end

  # Check if this deadline right is being used
  def in_use?
    usage_count > 0
  end

  private

  # Prevent deletion if deadline right is in use
  def cannot_delete_if_in_use
    return unless in_use?

    errors.add(:base, 'Cannot delete deadline right that is being used by due dates')
    throw :abort
  end

  before_destroy :cannot_delete_if_in_use
end
