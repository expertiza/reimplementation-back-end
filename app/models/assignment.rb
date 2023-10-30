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

  def num_review_rounds
    rounds_of_reviews
  end

  def add_participant(user_id)
    user = User.find_by(id: user_id)
    if user.nil?
      raise "The user account with the name #{user.name} does not exist. Please <a href='" +
              url_for(controller: 'users', action: 'new') + "'>create</a> the user first."
    end
    participant = Participant.find_by(assignment_id:id, user_id:user.id)
    if participant
      raise "The user #{user.name} is already a participant."
    end

    new_part = AssignmentParticipant.create(assignment_id: self.id,
                                            user_id: user.id)
    new_part.set_handle
    new_part
  end
 

  #removes participant from assignment
  def remove_participant(user_id)
    assignment_participant = AssignmentParticipant.where(assignment_id: self.id, user_id: user_id).first
    assignment_participant.destroy
  end

  def remove_assignment_from_course
    self.course_id = nil
    self
  end

  def assign_courses_to_assignment(course_id)
    assignment = Assignment.where(id: id).first
    assignment.course_id = course_id
    assignment
  end


  def copy_assignment()
    new_assignment = Assignment.create(name: "Copy of "+self.name, instructor_id: self.instructor_id, course_id: self.course_id)
    new_assignment

  end

end
