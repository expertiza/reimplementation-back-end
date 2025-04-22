class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', optional: true, inverse_of: false
  belongs_to :course, foreign_key: 'course_id', optional: true, inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  has_many :response_maps,
           class_name: 'ResponseMap',
           foreign_key: 'reviewer_id',
           dependent: :destroy,
           inverse_of: false

  # delegate :course, to: :assignment, allow_nil: true

  # Validations
  validates :user_id, presence: true
  # Validation: require either assignment_id or course_id
  validate :parent_absent?

  # Returns the full name of the associated user
  def name
    user.full_name
  end

  # Returns all responses submitted by this participant
  def responses
    response_maps.includes(:response).map(&:response)
  end

  # Returns the username of the associated user
  def username
    user.name
  end

  # Deletes the participant if no associations exist, or forces deletion if specifiedd
  def delete(force = nil)
    maps = ResponseMap.where('reviewee_id = ? or reviewer_id = ?', id, id)

    raise 'Associations exist for this participant.' unless force || (maps.blank? && team.nil?)

    force_delete(maps)
  end

  # Forcefully deletes response maps and the participant's team if necessary
  def force_delete(maps)
    maps && maps.each(&:destroy)
    if team && (team.teams_users.length == 1)
      team.delete
    elsif team
      team.teams_users.each { |teams_user| teams_user.destroy if teams_user.user_id == id }
    end
    destroy
  end

  # Determines the role of the participant based on their permissions
  def task_role
    task = 'participant'
    task = 'mentor'    if can_mentor
    task = 'reader'    if !can_submit && can_review   && can_take_quiz
    task = 'submitter' if  can_submit && !can_review  && !can_take_quiz
    task = 'reviewer'  if !can_submit && can_review   && !can_take_quiz
    task
  end

  # Exports participant data to a CSV file based on selected options
  def self.export(csv, parent_id, options)
    where(assignment_id: parent_id).find_each do |part|
      tcsv = []
      user = part.user
      tcsv.push(user.name, user.full_name, user.email) if options['personal_details'] == 'true'
      tcsv.push(user.role.name) if options['role'] == 'true'
      tcsv.push(user.institution.name) if options['parent'] == 'true'
      tcsv.push(user.email_on_submission, user.email_on_review, user.email_on_review_of_review) if options['email_options'] == 'true'
      tcsv.push(part.handle) if options['handle'] == 'true'
      csv << tcsv
    end
  end

  # Returns the list of exportable fields based on selected options
  def self.export_fields(options)
    fields = []
    fields += ['name', 'full name', 'email'] if options['personal_details'] == 'true'
    fields << 'role' if options['role'] == 'true'
    fields << 'parent' if options['parent'] == 'true'
    fields += ['email on submission', 'email on review', 'email on metareview'] if options['email_options'] == 'true'
    fields << 'handle' if options['handle'] == 'true'
    fields
  end


  private

  # Validates that either an assignment or course is present, but not both
  def parent_absent?
    if assignment.blank? && course.blank?
      errors.add(:base, "Either assignment or course must be present")
    elsif assignment.present? && course.present?
      errors.add(:base, "A Participant cannot be both an AssignmentParticipant and a CourseParticipant.")
    end
  end
end
