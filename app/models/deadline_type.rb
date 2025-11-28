# frozen_string_literal: true

class DeadlineType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_many :due_dates, foreign_key: :deadline_type_id, dependent: :restrict_with_exception

  # Semantic helper methods for deadline type identification
  def submission?
    name == 'submission'
  end

  def review?
    name == 'review'
  end

  def teammate_review?
    name == 'teammate_review'
  end

  def quiz?
    name == 'quiz'
  end

  def team_formation?
    name == 'team_formation'
  end

  def signup?
    name == 'signup'
  end

  def drop_topic?
    name == 'drop_topic'
  end

  # Display methods
  def display_name
    name.humanize
  end

  def to_s
    display_name
  end

  private

  # Ensure we maintain referential integrity
  def cannot_delete_if_has_due_dates
    return unless due_dates.exists?

    errors.add(:base, 'Cannot delete deadline type that has associated due dates')
    throw :abort
  end

  before_destroy :cannot_delete_if_has_due_dates
end
