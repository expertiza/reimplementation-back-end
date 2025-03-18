class Assignment < ApplicationRecord
  include MetricHelper
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'assignment_id', dependent: :destroy
  has_many :users, through: :participants, inverse_of: :assignment
  has_many :teams, class_name: 'Team', foreign_key: 'assignment_id', dependent: :destroy, inverse_of: :assignment
  has_many :invitations, class_name: 'Invitation', foreign_key: 'assignment_id', dependent: :destroy # , inverse_of: :assignment
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :questionnaires, through: :assignment_questionnaires
  has_many :response_maps, foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  has_many :sign_up_topics , class_name: 'SignUpTopic', foreign_key: 'assignment_id', dependent: :destroy
  has_many :due_dates,as: :parent, class_name: 'DueDate',  dependent: :destroy, as: :parent
  belongs_to :course, optional: true
  belongs_to :instructor, class_name: 'User', inverse_of: :assignments

  #This method return the value of the has_badge field for the given assignment object.
  attr_accessor :title, :description, :has_badge, :enable_pair_programming, :is_calibrated, :staggered_deadline

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
  def assign_course(course_id)
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
  def copy
    copied_assignment = Assignment.new(
        name: "Copy of #{self.name}",
        course_id: self.course_id
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
  
  def pair_programming_enabled?
    enable_pair_programming
  end
  
  def has_badge?
    has_badge
  end

  def staggered_and_no_topic?(topic_id)
    staggered_deadline? && topic_id.nil?
  end


  #This method return the value of the has_topics field for the given assignment object.
  # has_topics is of boolean type and is set true if there is any topic associated with the assignment.
  def topics?
    @has_topics ||= sign_up_topics.any?
  end

  #This method return if the given assignment is a team assignment.
  # Checks if the value of max_team_size for the given assignment object is greater than 1
  def team_assignment?
    !max_team_size.nil? && max_team_size > 1
  end

  #Auxiliary method for checking the validity of the field reviews_allowed for the given assignment object
  # Checks if review_allowed is not null and not negative.
  def valid_reviews_allowed?(reviews_allowed)
    reviews_allowed && reviews_allowed != -1
  end

  #method for checking if reviews_required are smaller than reviews_allowed for the given assignment object.
  def num_reviews_greater?(reviews_required, reviews_allowed)
    valid_reviews_allowed?(reviews_allowed) and reviews_required > reviews_allowed
  end

  #This method checks if for the given review type, required reviews and allowed reviews have valid order of values
  # Receives a parameter review_type and return an object with boolean value of 'success' and corresponding message
  # If the parameter is of a invalid type, the corresponding error message is received.
  def valid_num_review(review_type)
    if review_type=='review'
      #checks for reviews
      if num_reviews_greater?(num_reviews_required,num_reviews_allowed)
        {success: false, message: 'Number of reviews required cannot be greater than number of reviews allowed'}
      else
        {success: true}
      end

      #checks for meta-reviews
    elsif review_type == 'metareview'
        if num_reviews_greater?(num_metareviews_required,num_metareviews_allowed)
          {success: false, message: 'Number of metareviews required cannot be greater than number of metareviews allowed'}
        else
          {success: true}
        end

        #for invalid review_type
    else
      {success: false, message: 'Please enter a valid review type.'}
    end
  end


  #This method check if for the given assignment,different type of rubrics are used in different round.
  # Checks if for the given assignment any questionnaire is present with used_in_round field not nil.
  # Returns a boolean value whether such questionnaire is present.
  def varying_rubrics_by_round?
    rubric_with_round = AssignmentQuestionnaire.where(assignment_id: id).where.not(used_in_round: nil).first
    # Check if any rubric has a specified round
    rubric_with_round.present?
  end



end