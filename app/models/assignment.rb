###
####
#### We have spent a lot of time on refactoring this file, PLEASE consult with Expertiza development team before putting code in.
###
###

class Assignment < ApplicationRecord
  include MetricHelper
  belongs_to :course
  belongs_to :instructor, class_name: 'User', inverse_of: :assignments
  has_many :invitations
  has_many :questionnaires
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'assignment_id', dependent: :destroy
  has_many :users, through: :participants, inverse_of: :assignment
  has_many :teams, class_name: 'AssignmentTeam', foreign_key: 'assignment_id', dependent: :destroy, inverse_of: :assignment

  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def num_review_rounds
    rounds_of_reviews
  end

  # Initializes the directory path for 
  def path
    if course_id.nil? && instructor_id.nil?
      raise 'The path cannot be created. The assignment must be associated with either a course or an instructor.'
    end

    path_text = if !course_id.nil? && course_id > 0
                  "#{Rails.root}/pg_data/#{FileHelper.clean_path(instructor[:name])}/#{FileHelper.clean_path(course.directory_path)}/"
                else
                  "#{Rails.root}/pg_data/#{FileHelper.clean_path(instructor[:name])}/"
                end
    path_text + FileHelper.clean_path(directory_path)
  end
end
