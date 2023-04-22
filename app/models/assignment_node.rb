

class AssignmentNode < Node
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Assignment', foreign_key: 'node_object_id'

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)

  end

  def is_leaf
    true
  end

  def name

  end

  def directory

  end

  def creation_date

  end

  def modified_date

  end

  def course_id

  end

  def belongs_to_course?

  end

  def instructor_id

  end

  def institution_id

  end

  def private

  end

  def max_team_size

  end

  def topic_bidding?

  end

  def require_quiz?

  end

  def allow_suggestions?

  end

  def teams

  end
end
