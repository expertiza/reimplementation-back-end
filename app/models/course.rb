# frozen_string_literal: true

class Course < ApplicationRecord
  extend ImportableExportableHelper
  attr_accessor :institution_name, :instructor_name

  mandatory_fields :name, :directory_path, :institution_name, :instructor_name
  hidden_fields :id, :created_at, :updated_at, :institution_id, :instructor_id

  belongs_to :instructor, class_name: 'User', foreign_key: 'instructor_id'
  belongs_to :institution, foreign_key: 'institution_id'
  has_many :assignments, dependent: :destroy
  validates :name, presence: true
  validates :directory_path, presence: true
  validate :import_references_must_exist
  has_many :participants, class_name: 'CourseParticipant', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :course
  has_many :users, through: :course_participants, inverse_of: :course
  has_many :ta_mappings, dependent: :destroy
  has_many :tas, through: :ta_mappings, source: :ta
  has_many :teams, class_name: 'CourseTeam', foreign_key: 'parent_id', dependent: :destroy, inverse_of: :course

  before_validation :assign_import_references

  # Returns the submission directory for the course
  def path
    raise 'Path can not be created as the course must be associated with an instructor.' if instructor_id.nil?
    Rails.root + '/' + Institution.find(institution_id).name.gsub(" ", "") + '/' + User.find(instructor_id).name.gsub(" ", "") + '/' + directory_path + '/'
  end

  # Add a Teaching Assistant to the course
  def add_ta(user)
    if user.nil?
      return { success: false, message: "The user with id #{user.id} does not exist" }
    elsif TaMapping.exists?(user_id: user.id, course_id: id)
      return { success: false, message: "The user with id #{user.id} is already a TA for this course." }
    else
      ta_mapping = TaMapping.create(user_id: user.id, course_id: id)
      ta_role = Role.find_by(name: 'Teaching Assistant')
      user.update(role: ta_role) if ta_role
      if ta_mapping.save
        return { success: true, data: ta_mapping.slice(:course_id, :user_id) }
      else
        return { success: false, message: ta_mapping.errors }
      end
    end
  end

  # Removes Teaching Assistant from the course
  def remove_ta(user_id)
    ta_mapping = ta_mappings.find_by(user_id: user_id, course_id: :id)
    return { success: false, message: "No TA mapping found for the specified course and TA" } if ta_mapping.nil?
    ta = User.find(ta_mapping.user_id)
    ta_count = TaMapping.where(user_id: user_id).size - 1
    if ta_count.zero?
      ta.update(role: Role::STUDENT)
    end
    ta_mapping.destroy
    { success: true, ta_name: ta.name }
  end

  # Creates a copy of the course
  def copy_course
    new_course = dup
    new_course.directory_path += '_copy'
    new_course.name += '_copy'
    new_course.save
  end

  def institution_name
    @institution_name.presence || institution&.name
  end

  def instructor_name
    @instructor_name.presence || instructor&.name
  end

  private

  def assign_import_references
    self.institution = Institution.find_by(name: institution_name) if institution.blank? && institution_name.present?
    self.instructor = User.find_by(name: instructor_name) if instructor.blank? && instructor_name.present?
  end

  def import_references_must_exist
    if institution.blank? && institution_name.present?
      errors.add(:institution_name, 'could not be found')
    end

    if instructor.blank? && instructor_name.present?
      errors.add(:instructor_name, 'could not be found')
    end
  end
end
