module AuthorizationHelper
  # PUBLIC METHODS

  def current_user_has_super_admin_privileges?
    current_user_has_privileges_of?('Super Administrator')
  end

  def current_user_has_admin_privileges?
    current_user_has_privileges_of?('Administrator')
  end

  def current_user_has_instructor_privileges?
    current_user_has_privileges_of?('Instructor')
  end

  def current_user_has_ta_privileges?
    current_user_has_privileges_of?('Teaching Assistant')
  end

  def current_user_has_student_privileges?
    current_user_has_privileges_of?('Student')
  end

  def current_user_is_assignment_participant?(assignment_id)
    current_user.present? && AssignmentParticipant.exists?(parent_id: assignment_id, user_id: current_user.id)
  end

  def current_user_teaching_staff_of_assignment?(assignment_id)
    assignment = Assignment.find_by(id: assignment_id)
    current_user.present? &&
      (current_user_instructs_assignment?(assignment) || current_user_has_ta_mapping_for_assignment?(assignment))
  end

  def current_user_is_a?(role_name)
    current_user.present? && current_user.role&.name == role_name
  end

  def current_user_has_id?(id)
    current_user.present? && current_user.id == id.to_i
  end

  def current_user_created_bookmark_id?(bookmark_id)
    current_user.present? && !bookmark_id.nil? && Bookmark.find_by(id: bookmark_id.to_i)&.user_id == current_user.id
  end

  def given_user_can_submit?(user_id)
    given_user_can?(user_id, 'submit')
  end

  def given_user_can_review?(user_id)
    given_user_can?(user_id, 'review')
  end

  def given_user_can_take_quiz?(user_id)
    given_user_can?(user_id, 'take_quiz')
  end

  def given_user_can_read?(user_id)
    given_user_can_take_quiz?(user_id)
  end

  def response_edit_allowed?(map, user_id)
    assignment = map.reviewer.assignment
    if map.is_a?(ReviewResponseMap)
      reviewee_team = AssignmentTeam.find(map.reviewee_id)
      return current_user.present? &&
        (
          current_user_has_id?(user_id) ||
          reviewee_team.user?(current_user) ||
          current_user_has_admin_privileges? ||
          (current_user_is_a?('Instructor') && current_user_instructs_assignment?(assignment)) ||
          (current_user_is_a?('Teaching Assistant') && current_user_has_ta_mapping_for_assignment?(assignment))
        )
    end
    current_user_has_id?(user_id) ||
      (current_user_is_a?('Instructor') && current_user_instructs_assignment?(assignment)) ||
      (assignment.course && current_user_is_a?('Teaching Assistant') && current_user_has_ta_mapping_for_assignment?(assignment))
  end

  def user_logged_in?
    current_user.present?
  end

  def current_user_ancestor_of?(user)
    current_user.present? && user && current_user.recursively_parent_of(user)
  end

  def current_user_instructs_assignment?(assignment)
    current_user.present? && assignment &&
      (assignment.instructor_id == current_user.id ||
        (assignment.course_id && Course.find_by(id: assignment.course_id)&.instructor_id == current_user.id))
  end

  def current_user_has_ta_mapping_for_assignment?(assignment)
    current_user.present? && assignment && assignment.course &&
      TaMapping.exists?(ta_id: current_user.id, course_id: assignment.course.id)
  end

  def find_assignment_from_response_id(response_id)
    response = Response.find_by(id: response_id.to_i)
    return nil unless response
    response_map = response.response_map
    if response_map.assignment
      response_map.assignment
    else
      find_assignment_from_response_id(response_map.reviewed_object_id)
    end
  end

  def find_assignment_instructor(assignment)
    if assignment.course
      Course.find_by(id: assignment.course.id)&.instructor
    else
      assignment.instructor
    end
  end

  def current_user_instructs_or_tas_course?(course_id)
    return false unless current_user.present? && course_id.present?

    course = Course.find_by(id: course_id)
    return false unless course

    # Check if the current user is the instructor or a TA for the course
    course.instructor_id == current_user.id || TaMapping.exists?(ta_id: current_user.id, course_id: course.id)
  end

  # def current_user_instructs_or_tas_duty?(duty)
  #   return false unless current_user.present? && duty.present?

  #   # Check if the current user is the instructor of the duty
  #   return true if duty.instructor_id == current_user.id

  #   # Check if the current user is a TA for the course associated with the duty
  #   course_id = Course.find_by(instructor_id: duty.instructor_id)&.id
  #   current_user_instructs_or_tas_course?(course_id)
  # end

  # PRIVATE METHODS
  private

  def current_user_has_privileges_of?(role_name)
    current_user.present? && current_user.role&.all_privileges_of?(Role.find_by(name: role_name))
  end

  def given_user_can?(user_id, action)
    participant = Participant.find_by(id: user_id)
    return false if participant.nil?
    case action
    when 'submit'
      participant.can_submit
    when 'review'
      participant.can_review
    when 'take_quiz'
      participant.can_take_quiz
    else
      raise "Did not recognize user action '#{action}'"
    end
  end
end
