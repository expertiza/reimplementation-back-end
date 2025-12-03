# frozen_string_literal: true

class DeadlineRight < ApplicationRecord
  validates :name, presence: true, uniqueness: true

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

  # Display methods
  def to_s
    name
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
end
