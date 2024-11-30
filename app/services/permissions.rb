# app/services/permissions.rb
# This module centralizes permission logic to ensure DRY and consistent role-based checks across the application.
module Permissions
    # Determines if a user can manage courses (create or delete).
    # Admins, Instructors, and Super Administrators have this permission.
    def self.can_manage_courses?(user)
      user.role.super_administrator? || user.role.administrator? || user.role.instructor?
    end
  end
  