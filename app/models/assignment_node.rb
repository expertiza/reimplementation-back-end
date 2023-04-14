

class AssignmentNode < Node
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Assignment', foreign_key: 'node_object_id'

  def self.table
    'assignments'
  end

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)

  end

  def is_leaf
    true
  end

  def get_name

  end

  def get_directory

  end

  def get_creation_date

  end

  def get_modified_date

  end

  def get_course_id

  end

  def belongs_to_course?

  end

  def get_instructor_id

  end

  def get_institution_id

  end

  def get_private

  end

  def get_max_team_size

  end

  def is_intelligent?

  end

  def require_quiz?

  end

  def allow_suggestions?

  end

  def get_teams

  end
end