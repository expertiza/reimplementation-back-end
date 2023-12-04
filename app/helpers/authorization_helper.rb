require 'json_web_token'

module AuthorizationHelper
    # JWT Authentication Integration
    # Verifies and decodes a JWT token using the JsonWebToken class.
    # Returns user information in a HashWithIndifferentAccess or nil if the token is invalid.
    def jwt_verify_and_decode(token)
      begin
        decoded_token = JsonWebToken.decode(token)
        return HashWithIndifferentAccess.new(decoded_token)
      rescue JWT::DecodeError
        return nil
      end
    end
  
    # Check user privileges based on JWT claims
    # Given user information from the JWT and a required privilege, determine if the user has the required privilege.
    # Returns true if the user has the required privilege, false otherwise.

    def check_user_privileges(user_info, required_privilege)
        return false unless user_info.present? && user_info['role'].present?
    
        case required_privilege
        when 'Super-Administrator'
        return user_info['role'] == 'Super-Administrator'
        when 'Administrator'
        return user_info['role'] == 'Administrator'
        when 'Instructor'
        return user_info['role'] == 'Instructor'
        when 'Teaching Assistant'
        return user_info['role'] == 'Teaching Assistant'
        when 'Student'
        return user_info['role'] == 'Student'
        else
        return false
        end
    end
  
  
    # Determine if the currently logged-in user has the privileges of a Super-Admin
    # Checks if the user has Super-Administrator privileges based on the JWT token.
    def current_user_has_super_admin_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Super-Administrator') if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user has the privileges of an Admin (or higher)
    # Checks if the user has Administrator privileges based on the JWT token.
    def current_user_has_admin_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Administrator') if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user has the privileges of an Instructor (or higher)
    # Checks if the user has Instructor privileges based on the JWT token.
    def current_user_has_instructor_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Instructor') if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user has the privileges of a TA (or higher)
    # Checks if the user has Teaching Assistant privileges based on the JWT token.
    def current_user_has_ta_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Teaching Assistant') if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user has the privileges of a Student (or higher)
    # Checks if the user has Student privileges based on the JWT token.
    def current_user_has_student_privileges?(token)
      user_info = jwt_verify_and_decode(token)
      return check_user_privileges(user_info, 'Student') if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user is participating in an Assignment based on the assignment_id argument
    # Checks if the user is a participant in a specific assignment based on the JWT token.
    def current_user_is_assignment_participant?(token, assignment_id)
      user_info = jwt_verify_and_decode(token)
      return AssignmentParticipant.exists?(parent_id: assignment_id, user_id: user_info[:id]) if user_info.present?
  
      false
    end
  
    # Determine if the currently logged-in user is teaching staff of an Assignment based on the assignment_id argument
    # Checks if the user is an instructor or has TA mapping for a specific assignment based on the JWT token.
    def current_user_teaching_staff_of_assignment?(token, assignment_id)
      assignment = Assignment.find(assignment_id)
      user_info = jwt_verify_and_decode(token)
      user_info.present? &&
        (
          current_user_instructs_assignment?(assignment, user_info) ||
          current_user_has_ta_mapping_for_assignment?(assignment, user_info)
        )
    end
  
    # Determine if the currently logged-in user IS of the given role name
    # Checks if the user's role in the JWT token matches the provided role name.
    def current_user_is_a?(token, role_name)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:role] == role_name
    end
  
    # Determine if the current user has the passed in id value
    # Checks if the user's ID in the JWT token matches the provided ID.
    def current_user_has_id?(token, id)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:id].to_i == id.to_i
    end
  
    # Determine if the currently logged-in user created the bookmark with the given ID
    # Checks if the user in the JWT token created the bookmark with the specified ID.
    def current_user_created_bookmark_id?(token, bookmark_id)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? &&
             !bookmark_id.nil? &&
             Bookmark.find(bookmark_id.to_i).user_id == user_info[:id]
    rescue ActiveRecord::RecordNotFound
      false
    end
  
    # Determine if the given user can submit work
    # Checks if the user in the JWT token can submit work.
    def given_user_can_submit?(token, user_id)
      given_user_can?(token, user_id, 'submit')
    end
  
    # Determine if the given user can review work
    # Checks if the user in the JWT token can review work.
    def given_user_can_review?(token, user_id)
      given_user_can?(token, user_id, 'review')
    end
  
    # Determine if the given user can take quizzes
    # Checks if the user in the JWT token can take quizzes.
    def given_user_can_take_quiz?(token, user_id)
      given_user_can?(token, user_id, 'take_quiz')
    end
  
    # Determine if the given user can read work
    # Checks if the user in the JWT token can read work.
    def given_user_can_read?(token, user_id)
      given_user_can_take_quiz?(token, user_id)
    end
  
    # Determine if response editing is allowed for the given user in the specified map
    # Checks if the user in the JWT token is allowed to edit the response based on the map and user_id.
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
  
    # Determine if there is a current user
    # Checks if there is a current user based on the presence of a valid JWT token.
    def user_logged_in?(token)
      jwt_verify_and_decode(token).present?
    end
  
    # Determine if the currently logged-in user is an ancestor of the passed in user
    # Checks if the user in the JWT token is an ancestor of the specified user.
    def current_user_ancestor_of?(user, token)
      user_info = jwt_verify_and_decode(token)
      return user_info.present? && user_info[:id].recursively_parent_of(user) if user
  
      false
    end
  
    # Recursively find an assignment for a given Response id. Because a ResponseMap
    # can either point to an Assignment or another Response, recursively search until the
    # ResponseMap object's reviewed_object_id points to an Assignment.
    def find_assignment_from_response_id(response_id)
      response = Response.find(response_id.to_i)
      response_map = response.response_map
      response_map.assignment || find_assignment_from_response_id(response_map.reviewed_object_id)
    end
  
    # Finds the assignment_instructor for a given assignment. If the assignment is associated with
    # a course, the instructor for the course is returned. If not, the instructor associated
    # with the assignment is return.
    def find_assignment_instructor(assignment)
      if assignment.course
        Course.find_by(id: assignment.course.id).instructor
      else
        assignment.instructor
      end
    end
  
    private
  
    # Determine if the currently logged-in user has the privileges of the given role name (or higher privileges)
    # Let the Role model define this logic for the sake of DRY
    # If there is no currently logged-in user simply return false
    def current_user_has_privileges_of?(role_name, user_info)
      user_info.present? && user_info[:role].has_all_privileges_of?(Role.find_by(name: role_name))
    end
  
    # Determine if the given user is a participant of some kind
    # who is allowed to perform the given action ("submit", "review", "take_quiz")
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
        raise "Did not recognize user action '" + action + "'"
      end
    end
  
    def current_user_and_role_exist?(user_info)
      user_info.present? && user_info['role'].present?
    end
  end
  
