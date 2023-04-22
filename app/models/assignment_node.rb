

class AssignmentNode < Node
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'node_object_id'
  belongs_to :node_object, class_name: 'Assignment', foreign_key: 'node_object_id'

  def self.get(sortvar = nil, sortorder = nil, user_id = nil, show = nil, parent_id = nil, _search = nil)
    if show
      conditions = if User.find(user_id).role.name != 'Teaching Assistant'
                     'assignments.instructor_id = ?'
                   else
                     'assignments.course_id in (?)'
                   end
    else
      if User.find(user_id).role.name != 'Teaching Assistant'
        conditions = '(assignments.private = 0 or assignments.instructor_id = ?)'
        values = user_id
      else
        conditions = '(assignments.private = 0 or assignments.course_id in (?))'
        values = Ta.get_mapped_courses(user_id)
      end
    end
    conditions += " and course_id = #{parent_id}" if parent_id
    sortvar ||= 'created_at'
    sortorder ||= 'desc'
    find_conditions = [conditions, values]
    includes(:assignment).where(find_conditions).order("assignments.#{sortvar} #{sortorder}")
  end

  def self.leaf?
    true
  end

  def name
    @assign_node ? @assign_node.name : Assignment.find_by(id: node_object_id).try(:name)
  end

  def directory
    @assign_node ? @assign_node.directory_path : Assignment.find_by(id: node_object_id).try(:directory_path)
  end

  def creation_date
    @assign_node ? @assign_node.created_at : Assignment.find_by(id: node_object_id).try(:created_at)
  end

  def modified_date
    @assign_node ? @assign_node.updated_at : Assignment.find_by(id: node_object_id).try(:updated_at)
  end

  def course_id
    @assign_node ? @assign_node.course_id : Assignment.find_by(id: node_object_id).try(:course_id)
  end

  def belongs_to_course?
    !get_course_id.nil?
  end

  def instructor_id
    @assign_node ? @assign_node.instructor_id : Assignment.find_by(id: node_object_id).try(:instructor_id)
  end

  def institution_id
    Assignment.find_by(id: node_object_id).try(:institution_id)
  end

  def private?
    Assignment.find_by(id: node_object_id).try(:private)
  end

  def max_team_size
    Assignment.find_by(id: node_object_id).try(:max_team_size)
  end

  def topic_bidding?
    # TODO
  end

  def require_quiz?
    Assignment.find_by(id: node_object_id).try(:require_quiz)
  end

  def allow_suggestions?
    Assignment.find_by(id: node_object_id).try(:allow_suggestions)
  end

  def teams
    TeamNode.get(node_object_id)s
  end
end
