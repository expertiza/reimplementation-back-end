

class AssignmentNode < Node
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Assignment', foreign_key: 'node_object_id'

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)
    # if show
    #   conditions = if User.find(user_id).role.name != 'Teaching Assistant'
    #                  'assignments.instructor_id = ?'
    #                else
    #                  'assignments.course_id in (?)'
    #                end
    # else
    #   if User.find(user_id).role.name != 'Teaching Assistant'
    #     conditions = '(assignments.private = 0 or assignments.instructor_id = ?)'
    #     values = user_id
    #   else
    #     conditions = '(assignments.private = 0 or assignments.course_id in (?))'
    #     values = Ta.get_mapped_courses(user_id)
    #   end
    # end
    conditions = get_privacy_clause(show, user_id)
    conditions += " and course_id = #{parent_id}" if parent_id
    sortvar ||= 'created_at'
    sortorder ||= 'desc'
    find_conditions = [conditions, values]
    includes(:assignment).where(find_conditions).order("assignments.#{sortvar} #{sortorder}")
  end

  def self.get_privacy_clause(show, user_id)
    query_user = User.find_by(id: user_id)

    if query_user.teaching_assistant?
      clause = "assignments.course_id in (#{Ta.get_mapped_courses(user_id)})"
    else
      clause = "assignments.instructor_id = #{user_id}"
    end

    if show
      clause
    else
      "(assignments.private = 0 or #{clause})"
    end
  end

  def self.leaf?
    true
  end

  # With this functionality, a database lookup of Assignemnt is performed
  # if not stored in an object variable. Once search is performed, store it
  # Otherwise,  we use the existing cached Assignment extract a specific parameter
  def cached_assignment_lookup(parameter)
    if !@assignment_node
      @assignment_node = Assignment.find_by(id: node_object_id)
    end
    @assignment_node.try(parameter)
  end

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
    !get_course_id.nil?
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

  def teams
    TeamNode.get(node_object_id)
  end
end
