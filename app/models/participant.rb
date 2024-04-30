class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  self.inheritance_column = :_type_disabled

  def fullname
    user.fullname
  end

  def as_json(options = nil)
    super(options).merge({
                           user: user.as_json # include all attributes of the user
                         })
  end
end
