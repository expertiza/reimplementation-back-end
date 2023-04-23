class AssignmentNode < Node
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Assignment', foreign_key: 'node_object_id'

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil)
    conditions = get_privacy_clause(show, user_id)
    conditions += " and course_id = #{parent_id}" if parent_id
    sortvar ||= 'created_at'
    sortorder ||= 'desc'
    includes(:assignment).where([conditions]).order("assignments.#{sortvar} #{sortorder}")
  end

  # Generate the contents of a WHERE clause that accounts for assignment privacy and user permissions.
  # user_id: The user being used in the query, used for permission lookup.
  # show: If false, include all public assignments as well.
  def self.get_privacy_clause(show, user_id)
    query_user = User.find_by(id: user_id)

    if query_user && query_user.teaching_assistant?
      clause = "assignments.course_id in (#{Ta.get_mapped_courses(user_id)})"
    else
      clause = "assignments.instructor_id = #{user_id}"
    end

    show ? clause : "(assignments.private = 0 or #{clause})"
  end

  def self.leaf?
    true
  end

  def teams
    TeamNode.get(node_object_id)
  end

  # Lookup a specific parameter on the object's assignment database object.
  # This method uses a cached object to reduce database lookups on subsequent calls.
  # parameter is a symbol representing the property being queried.
  def cached_assignment_lookup(parameter)
    if !@cached_assignment
      @cached_assignment = Assignment.find_by(id: node_object_id)
    end
    @cached_assignment.try(parameter)
  end

  # Property lookup methods for the attached database object
  def name
    cached_assignment_lookup(:name)
  end

  def directory
    cached_assignment_lookup(:directory_path)
  end

  def creation_date
    cached_assignment_lookup(:created_at)
  end

  def modified_date
    cached_assignment_lookup(:updated_at)
  end

  def course_id
    cached_assignment_lookup(:course_id)
  end

  def belongs_to_course?
    !course_id.nil?
  end

  def instructor_id
    cached_assignment_lookup(:instructor_id)
  end

  def institution_id
    cached_assignment_lookup(:institution_id)
  end

  def private?
    cached_assignment_lookup(:private4)
  end

  def max_team_size
    cached_assignment_lookup(:max_team_size)
  end

  def topic_bidding?
    cached_assignment_lookup(:is_intelligent)
  end

  def require_quiz?
    cached_assignment_lookup(:require_quiz)
  end

  def allow_suggestions?
    cached_assignment_lookup(:allow_suggestions)
  end
end
