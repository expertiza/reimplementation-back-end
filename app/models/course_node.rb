class CourseNode < Node
  belongs_to :course, class_name: 'Course', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Course', foreign_key: 'node_object_id'

  def self.create_course_node(course)
  end

  def self.get(_sortvar = 'name', _sortorder = 'desc', user_id = nil, show = nil, _parent_id = nil, _search = nil)

  end

  def self.get_course_query_conditions(show = nil, user_id = nil)

  end

  def self.get_courses_managed_by_user(user_id = nil)

  end

  def self.parent_id

  end


  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, _parent_id = nil, search = nil)
  end

  def name
  end

  def directory
  end

  def creation_date
  end

  def modified_date
  end

  def private?
  end

  def instructor_id
  end

  def institution_id
  end

  def teams
  end

  def survey_distribution_id
  end
end
