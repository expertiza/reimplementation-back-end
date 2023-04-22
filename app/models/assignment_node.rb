

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

  def private?

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
