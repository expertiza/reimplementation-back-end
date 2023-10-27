class Assignment < ApplicationRecord
  include MetricHelper
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'parent_id', dependent: :destroy
  has_many :users, through: :participants, inverse_of: :assignment
  has_many :teams, class_name: 'AssignmentTeam', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :assignment
  has_many :invitations, class_name: 'Invitation', foreign_key: 'assignment_id', dependent: :destroy # , inverse_of: :assignment
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :questionnaires, through: :assignment_questionnaires
  has_many :response_maps, foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewed_object_id', dependent: :destroy, inverse_of: :assignment

  belongs_to :course
  belongs_to :instructor, class_name: 'User', inverse_of: :assignments


  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def num_review_rounds
    rounds_of_reviews
  end

  def add_participant(can_submit,can_review,can_take_quiz)
    user = User.find_by(id: @current_user.id)
    if user.nil?
      raise "The user account with the name #{user.name} does not exist. Please <a href='" +
              url_for(controller: 'users', action: 'new') + "'>create</a> the user first."
    end
    participant = AssignmentParticipant.find_by(assignment_id:id, user_id:user.id)
    raise "The user #{user.name} is already a participant." if participant

    new_part = AssignmentParticipant.create(assignment_id: id,
                                            user_id: user.id,
                                            # permission_granted: user.master_permission_granted,
                                            can_submit: can_submit,
                                            can_review: can_review,
                                            can_take_quiz: can_take_quiz)
    new_part.set_handle
  end
  def remove_assignment_from_course
    oldpath = get_path
    nullify_course_id
    save_changes
    newpath = get_path
    update_file_location(oldpath, newpath)
  end
  def save_changes
    save
  end
  def get_path
    begin
      path
    rescue StandardError
      nil
    end
  end
  def nullify_course_id
    self.course_id = nil
  end
  def update_file_location(oldpath, newpath)
    FileHelper.update_file_location(oldpath,newpath)
  end
  def path
    if course_id.nil? && instructor_id.nil?
      raise 'The path cannot be created. The assignment must be associated with either a course or an instructor.'
    end

    path_text = if !course_id.nil? && course_id > 0
                  Rails.root.to_s + '/pg_data/' + clean_path(instructor[:name]) + '/' +
                    clean_path(course.directory_path) + '/'
                else
                  Rails.root.to_s + '/pg_data/' + clean_path(instructor[:name]) + '/'
                end
    path_text += clean_path(directory_path)
    path_text
  end
  def clean_path(name)
    FileHelper.clean_path(name)
  end

  def remove_assignment_participant(assignment_participant)
    return false unless assignment_participant
    assignment_participant.destroy_all
    undo_link "The user \"#{assignment_participant.name}\" has been successfully removed from the assignment."
  end

  def remove_participant
    assignment_participant = AssignmentParticipant.where(assignment_id: params[:assignment_id],user_id:params[:user_id]
    remove_assignment_participant(assignment_participant)
  end

end
