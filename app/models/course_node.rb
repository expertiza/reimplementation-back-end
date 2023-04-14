class CourseNode < Node
  belongs_to :course, class_name: 'Course', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Course', foreign_key: 'node_object_id'

  def self.create_course_node(course)
  end

  def self.table
  end


  def self.get(_sortvar = 'name', _sortorder = 'desc', user_id = nil, show = nil, _parent_id = nil, _search = nil)

  end

  def self.get_course_query_conditions(show = nil, user_id = nil)

  end

  def self.get_courses_managed_by_user(user_id = nil)

  end

  def self.get_parent_id

  end


  def get_children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, _parent_id = nil, search = nil)
  end

  def get_name
  end

  def get_directory
  end

  def get_creation_date
  end

  def get_modified_date
  end

  def private?
  end

  def get_instructor_id
  end

  def get_institution_id
  end

  def get_teams
  end

  def get_survey_distribution_id
  end
end