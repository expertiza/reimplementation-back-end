class Assignment < ApplicationRecord
  include MetricHelper
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'assignment_id', dependent: :destroy
  has_many :users, through: :participants, inverse_of: :assignment
  #has_many :teams, class_name: 'AssignmentTeam', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :assignment
  has_many :invitations, class_name: 'Invitation', foreign_key: 'assignment_id', dependent: :destroy # , inverse_of: :assignment
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :questionnaires, through: :assignment_questionnaires
  has_many :response_maps, foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  
  belongs_to :course, optional: true
  belongs_to :instructor, class_name: 'User', inverse_of: :assignments


  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def teams?
    @has_teams ||= teams.any?
  end
  def num_review_rounds
    rounds_of_reviews
  end

  # Add a participant to the assignment based on the provided user_id.
  # This method first finds the User with the given user_id. If the user does not exist, it raises an error.
  # It then checks if the user is already a participant in the assignment. If so, it raises an error.
  # If the user is not a participant, a new AssignmentParticipant is created and associated with the assignment.
  # The participant's handle is set, and the newly created participant is returned.
  # Raises an error if the user does not exist or if the user is already a participant.
  # Returns the newly created AssignmentParticipant.
  def add_participant(user_id)
    # Find the User with the provided user_id
    user = User.find_by(id: user_id)
    # Check if the user exists
    if user.nil?
      raise "The user account does not exist"
    end
    # Check if the user is already a participant in the assignment
    participant = Participant.find_by(assignment_id:id, user_id:user.id)
    if participant
      # Raises error if the user is already a participant
      raise "The user #{user.name} is already a participant."
    end
    # Create a new AssignmentParticipant associated with the assignment and user
    new_part = AssignmentParticipant.create(assignment_id: self.id,
                                            user_id: user.id)
    # Set the participant's handle
    new_part.set_handle
    # Return the newly created AssignmentParticipant
    new_part
  end


  # Remove a participant from the assignment based on the provided user_id.
  # This method finds the AssignmentParticipant with the given assignment_id and user_id,
  # and then deletes the corresponding record from the database.
  # No return value; the participant is removed from the assignment.
  def remove_participant(user_id)
    # Find the AssignmentParticipant associated with this assignment and user
    assignment_participant = AssignmentParticipant.where(assignment_id: self.id, user_id: user_id).first
    # Delete the AssignmentParticipant record
    if assignment_participant
      assignment_participant.destroy
    end
  end

  # Remove the assignment from the associated course.
  # This method sets the course_id of the assignment to nil, effectively removing its course association.
  # Returns the modified assignment object with course_id set to nil.
  def remove_assignment_from_course
    # Set the course_id of the assignment to nil
    self.course_id = nil
    # Return the modified assignment
    self
  end



  # Assign a course to the assignment based on the provided course_id.
  # If the assignment already belongs to the specified course, an error is raised.
  # Returns the modified assignment object with the updated course assignment.
  def assign_courses_to_assignment(course_id)
    # Find the assignment by its ID
    assignment = Assignment.where(id: id).first
    # Check if the assignment already belongs to the provided course_id
    if assignment.course_id == course_id
      # Raises error if the assignment already belongs to the provided course_id
      raise "The assignment already belongs to this course id."
    end
    # Update the assignment's course assignment
    assignment.course_id = course_id
    # Return the modified assignment
    assignment
  end


  # Create a copy of the assignment, including its name, instructor, and course assignment.
  # The new assignment is named "Copy of [original assignment name]".
  # Returns the newly created assignment object, which is a copy of the original assignment.
  def copy_assignment()
    copied_assignment = Assignment.new(
        name: "Copy of #{self.name}",
        course_id: self.course_id,
      )

    # Assign the correct instructor to the copied assignment
    copied_assignment.instructor = self.instructor

    # Save the copied assignment to the database
    copied_assignment.save

    copied_assignment

  end
  def is_calibrated?
    is_calibrated
  end

end
