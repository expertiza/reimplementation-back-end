class DueDate < ApplicationRecord
  include Comparable

  belongs_to :parent, polymorphic: true
  validate :due_at_is_valid_datetime

  def due_at_is_valid_datetime
    if due_at.present?
      errors.add(:due_at, 'must be a valid datetime') if (
        begin
          DateTime.strptime(due_at.to_s, '%Y-%m-%d %H:%M:%S')
        rescue StandardError
          ArgumentError
        end ) == ArgumentError
    end
  end

  def <=>(other)
    self.due_at <=> other.due_at
  end

  def self.sort_due_dates(due_dates)
    due_dates.sort
  end
  
  def self.next_due_date(due_dates)
    sorted_due_dates = sort_due_dates(due_dates)
    sort_due_dates.find { |due_date| due_date.due_at > DateTime.now }
  end
end