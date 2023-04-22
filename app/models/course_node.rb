class CourseNode < Node
  belongs_to :course, class_name: 'Course', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Course', foreign_key: 'node_object_id'

  def self.create_course_node(course)
  end

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
