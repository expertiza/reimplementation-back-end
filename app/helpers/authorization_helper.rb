module AuthorizationHelper
    def jwt_verify_and_decode(token)
      begin
        decoded_token = JsonWebToken.decode(token)
        return HashWithIndifferentAccess.new(decoded_token)
      rescue JWT::DecodeError
        return nil
      end
    end
  
    def check_user_privileges(user_info, required_privilege)
      return false unless user_info.present? && user_info[:role].present?
  
      case required_privilege
      when 'Super-Administrator'
        return user_info[:role] == 'Super-Administrator'
      when 'Administrator'
        return user_info[:role] == 'Administrator'
      when 'Instructor'
        return user_info[:role] == 'Instructor'
      when 'Teaching Assistant'
        return user_info[:role] == 'Teaching Assistant'
      when 'Student'
        return user_info[:role] == 'Student'
      else
        return false
      end
    end
  
    def current_user_has_super_admin_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Super-Administrator') if user_info.present?
  
      false
    end
  
    def current_user_has_admin_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Administrator') if user_info.present?
  
      false
    end
  
    def current_user_has_instructor_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Instructor') if user_info.present?
  
      false
    end
  
    def current_user_has_ta_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Teaching Assistant') if user_info.present?
  
      false
    end
  
    def current_user_has_student_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Student') if user_info.present?
  
      false
    end
  
    def current_user_is_assignment_participant?(token, assignment_id)
      user_info = jwt_verify_and_decode(token)
      return AssignmentParticipant.exists?(parent_id: assignment_id, user_id: user_info[:id]) if user_info.present?
  
      false
    end
  
    def current_user_teaching_staff_of_assignment?(token, assignment_id)
      assignment = Assignment.find(assignment_id)
      user_info = jwt_verify_and_decode(token)
      user_info.present? &&
        (
          current_user_instructs_assignment?(assignment, user_info) ||
          current_user_has_ta_mapping_for_assignment?(assignment, user_info)
        )
    end
  
    def current_user_is_a?(token, role_name)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:role] == role_name
    end
  
    def current_user_has_id?(token, id)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:id].to_i == id.to_i
    end
  
    def current_user_created_bookmark_id?(token, bookmark_id)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? &&
             !bookmark_id.nil? &&
             Bookmark.find(bookmark_id.to_i).user_id == user_info[:id]
    rescue ActiveRecord::RecordNotFound
      false
    end
  
    def given_user_can_submit?(token, user_id)
      given_user_can?(token, user_id, 'submit')
    end
  
    def given_user_can_review?(token, user_id)
      given_user_can?(token, user_id, 'review')
    end
  
    def given_user_can_take_quiz?(token, user_id)
      given_user_can?(token, user_id, 'take_quiz')
    end
  
    def given_user_can_read?(token, user_id)
      given_user_can_take_quiz?(token, user_id)
    end
  
    def response_edit_allowed?(token, map, user_id)
      assignment = map.reviewer.assignment
      if map.is_a? ReviewResponseMap
        reviewee_team = AssignmentTeam.find(map.reviewee_id)
        return user_info.present? &&
               (
                 current_user_has_id?(token, user_id) ||
                 reviewee_team.user?(user_info) ||
                 current_user_has_admin_privileges?(token) ||
                 (current_user_is_a?(token, 'Instructor') && current_user_instructs_assignment?(assignment, user_info)) ||
                 (current_user_is_a?(token, 'Teaching Assistant') && current_user_has_ta_mapping_for_assignment?(assignment, user_info))
               )
      end
      current_user_has_id?(token, user_id) ||
        (current_user_is_a?(token, 'Instructor') && current_user_instructs_assignment?(assignment, user_info)) ||
        (assignment.course && current_user_is_a?(token, 'Teaching Assistant') && current_user_has_ta_mapping_for_assignment?(assignment, user_info))
    end
  
    def user_logged_in?(token)
      jwt_verify_and_decode(token).present?
    end
  
    def current_user_ancestor_of?(user, token)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:id].recursively_parent_of(user) if user
  
      false
    end
  
    def current_user_instructs_assignment?(assignment, user_info)
      user_info.present? && !assignment.nil? && (
        assignment.instructor_id == user_info[:id] ||
        (assignment.course_id && Course.find(assignment.course_id).instructor_id == user_info[:id])
      )
    end
  
    def current_user_has_ta_mapping_for_assignment?(assignment, user_info)
      user_info.present? && !assignment.nil? && TaMapping.exists?(ta_id: user_info[:id], course_id: assignment.course.id)
    end
  
    def find_assignment_from_response_id(response_id)
      response = Response.find(response_id.to_i)
      response_map = response.response_map
      response_map.assignment || find_assignment_from_response_id(response_map.reviewed_object_id)
    end
  
    def find_assignment_instructor(assignment)
      if assignment.course
        Course.find_by(id: assignment.course.id).instructor
      else
        assignment.instructor
      end
    end
  
    private
  
    def current_user_has_privileges_of?(role_name, user_info)
      user_info.present? && user_info[:role].has_all_privileges_of?(Role.find_by(name: role_name))
    end
  
    def given_user_can?(token, user_id, action)
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
  
    def current_user_and_role_exist?(user_info)
      user_info.present? && user_info[:role].present?
    end
  end
  
