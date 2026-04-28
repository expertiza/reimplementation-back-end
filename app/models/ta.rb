# frozen_string_literal: true

class Ta < User
  validates :parent_id, presence: true

  # Get all users whose parent is the TA
  # @return [Array<User>] all users that belongs to courses that is mapped to the TA
  def managed_users
    User.where(parent_id: id).to_a
  end

  def my_instructor
    parent_id
  end

  def courses_assisted_with
    Course.joins(:ta_mappings).where(ta_mappings: { user_id: id }).distinct.to_a
  end
end
