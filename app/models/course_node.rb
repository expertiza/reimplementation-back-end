class CourseNode < Node
  belongs_to :course, class_name: 'Course', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Course', foreign_key: 'node_object_id'

  def self.create_course_node(course)
    parent_id = CourseNode.get_parent_id
    @course_node = CourseNode.new
    @course_node.node_object_id = course.id
    @course_node.parent_id = parent_id if parent_id
    @course_node.save
  end
s
  def self.get(_sortvar = 'name', _sortorder = 'desc', user_id = nil, show = nil, _parent_id = nil, _search = nil)
    sortvar = 'created_at'
    if Course.column_names.include? sortvar
      includes(:course).where([get_course_query_conditions(show, user_id), get_courses_managed_by_user(user_id)])
                       .order("courses.#{sortvar} desc")
    end
  end

  def self.get_course_query_conditions(show = nil, user_id = nil)
    query_user = User.find_by(id: user_id)

    if query_user && query_user.teaching_assistant?
      if show
        "courses.id in (?)"
      else
        "((courses.private = 0 and courses.instructor_id != #{user_id}) or courses.instructor_id = #{user_id})"
      end
    else
      if show
        "courses.instructor_id = #{user_id}"
      else
        "(courses.private = 0 or courses.instructor_id = #{user_id})"
      end
    end
  end

  def self.get_courses_managed_by_user(user_id = nil)
    current_user = User.find(user_id)
    if current_user.teaching_assistant?
      Ta.get_mapped_courses(user_id)
    else
      user_id
    end
  end

  def self.parent_id
    folder = TreeFolder.find_by(name: 'Courses')
    parent = FolderNode.find_by(node_object_id: folder.id)
    parent.id if parent
  end


  def children(sortvar = nil, sortorder = nil, user_id = nil, show = nil, _parent_id = nil, search = nil)
    AssignmentNode.get(sortvar, sortorder, user_id, show, node_object_id, search)
  end

  def cached_course_lookup(parameter)
    if !@course_node
      @course_node = Course.find_by(id: node_object_id)
    end
    @course_node.try(parameter)
  end

  def name
    cached_course_lookup(:name)
  end

  def directory
    cached_course_lookup(:directory)
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

  def teams
    TeamNode.get(node_object_id)
  end

  def survey_distribution_id
    cached_course_lookup(:survey_distribution_id)
  end
end
