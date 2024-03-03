
class Action
  LIST = 'index'.freeze
  SHOW = 'show'.freeze
  NEW = 'new'.freeze
  CREATE = 'create'.freeze
  EDIT = 'edit'.freeze
  UPDATE = 'update'.freeze
  DELETE = 'destroy'.freeze

  # An array of all roles
  ALL_ROLES = [LIST, VIEW, CREATE, UPDATE, DELETE].freeze

  # Example method to check if a role is admin
  def self.LIST
    LIST
  end
  def self.SHOW
    SHOW
  end
  def self.NEW
    NEW
  end
  def self.CREATE
    CREATE
  end
  def self.EDIT
    EDIT
  end
  def self.UPDATE
    UPDATE
  end
  def self.DELETE
    DELETE
  end
end