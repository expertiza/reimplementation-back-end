# This module's main purpose is to handle any validation for permissions related to roles
# that have been established within Expertiza.
# 
# E2511: Currently, this class is meant to replace an old implementation requiring the
# roles to have its permissions be explicity defined in participants_helper via a large
# set of boolean values. This implementation seeks to reimplement this using a Strategy
# Design Pattern where RoleContext uses any relevant strategies to execute necessary
# functions related to a given Role. This can be extended in the future to include
# other Role functions if necessary as well
module RoleStrategy

  # This should validate whether or not a given role is able to access a certain
  # functionality or not.
  # @raise [NotImplementedError] if the function is not implemented
  def validate_permissions
    raise NotImplementedError("Classes that inherit from RoleStrategy must implement validate_permissions")
  end

  # This should return a dictionary of permissions allocated to a given role
  # @raise [NotImplementedError] if the function is not implemented
  def get_permissions
    raise NotImplementedError("Classes that inherit from RoleStrategy must implement validate_permissions")
  end
end
