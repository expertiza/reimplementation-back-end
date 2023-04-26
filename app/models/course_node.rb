class CourseNode < Node
  belongs_to :course, class_name: 'Course', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Course', foreign_key: 'node_object_id'

  def self.create_course_node(course)
    parent_id = CourseNode.parent_id
    @course_node = CourseNode.new
    @course_node.node_object_id = course.id
    @course_node.parent_id = parent_id if parent_id
    @course_node.save
  end

  def self.get(_sortvar = 'name', _sortorder = 'desc', user_id = nil, show = nil, _parent_id = nil)
    sortvar = 'created_at'
    if Course.column_names.include? sortvar
      includes(:course).where([get_privacy_clause(show, user_id)])
                       .order("courses.#{sortvar} desc")
    end
  end

  # Generate the contents of a WHERE clause that accounts for course privacy and user permissions.
  # user_id: The user being used in the query, used for permission lookup.
  # show: If false, include all public courses as well.
  def self.get_privacy_clause(show = nil, user_id = nil)
    query_user = User.find_by(id: user_id)

    if query_user && query_user.teaching_assistant?
      clause = "courses.id in (?)"
    else
      clause = "courses.instructor_id = #{user_id}"
    end

    show ? clause : "(courses.private = 0 or #{clause})"
  end


  def self.parent_id
    folder = TreeFolder.find_by(name: 'Courses')
    parent = FolderNode.find_by(node_object_id: folder.id)
    parent.id if parent
  end


  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, _parent_id = nil, search = nil)
    AssignmentNode.get(sortvar, sortorder, user_id, show, node_object_id, search)
  end

  def teams
    TeamNode.get(node_object_id)
  end

  # Lookup a specific parameter on the object's course database object.
  # This method uses a cached object to reduce database lookups on subsequent calls.
  # parameter is a symbol representing the property being queried.
  def cached_course_lookup(parameter)
    if !@cached_course
      @cached_course = Course.find_by(id: node_object_id)
    end
    @cached_course.try(parameter)
  end

  # Property lookup methods for the attached database object
  def name
    cached_course_lookup(:name)
  end

  def directory_path
    cached_course_lookup(:directory_path)
  end

  def creation_date
    cached_course_lookup(:created_at)
  end

  def modified_date
    cached_course_lookup(:updated_at)
  end

  def private?
    cached_course_lookup(:private)
  end

  def instructor_id
    cached_course_lookup(:instructor_id)
  end

  def institution_id
    cached_course_lookup(:institutions_id)
  end

  def survey_distribution_id
    cached_course_lookup(:survey_distribution_id)
  end
end
