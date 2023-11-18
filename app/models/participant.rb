class Participant < ApplicationRecord

  # paper trail is used to keep track of the changes that are made to the code (does not affect the codebase in anyway)
  # has_paper_trail
  belongs_to :user
  belongs_to :topic, class_name: 'SignUpTopic', inverse_of: false
  belongs_to :assignment, foreign_key: 'parent_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  has_many   :reviews, class_name: 'ResponseMap', foreign_key: 'reviewer_id', dependent: :destroy, inverse_of: false
  has_many   :team_reviews, class_name: 'ReviewResponseMap', foreign_key: 'reviewer_id', dependent: :destroy, inverse_of: false
  has_many :response_maps, class_name: 'ResponseMap', foreign_key: 'reviewee_id', dependent: :destroy, inverse_of: false
  has_many :awarded_badges, dependent: :destroy
  has_many :badges, through: :awarded_badges
  has_one :review_grade, dependent: :destroy
  #validation to ensure grade is of type numerical or nil
  validates :grade, numericality: { allow_nil: true }
  # has_paper_trail
  delegate :course, to: :assignment
  delegate :current_stage, to: :assignment
  delegate :stage_deadline, to: :assignment

  PARTICIPANT_TYPES = %w[Course Assignment].freeze

  # define a constant to hold the duty title Mentor
  # this will be used in the duty column of the participant
  # table to define participants who can mentor teams, topics, or assignments
  # since the column's type is VARCHAR(255), other string constants should be
  # defined here to add different duty titles
  DUTY_MENTOR = 'mentor'.freeze

  # finds team of the participant 
  def team
    TeamsParticipant.find_by(participant_id: id).try(:team)
  end

  def responses
    response_maps.map(&:response)
  end

  def name(ip_address = nil)
    user.name(ip_address)
  end

  def fullname(ip_address = nil)
    user.fullname(ip_address)
  end

  def handle(ip_address = nil)
    User.anonymized_view?(ip_address) ? 'handle' : self[:handle]
  end

  def delete(force = nil)
    # find if the participant is either a reviewer or reviewee of an assignment
    maps = ResponseMap.where('reviewee_id = ? or reviewer_id = ?', id, id)
    # raise if associations exist for the participant unless force
    raise 'Associations exist for this participant.' unless force || (maps.blank? && team.nil?)

    # delete response maps associated with the participant
    maps && maps.destroy_all
    # remove the participant from the team
    team && team.teams_participants.find_by(participant_id: id).destroy
    destroy
  end

  def topic_name
    if topic.nil? || topic.topic_name.empty?
      '<center>&#8212;</center>' # em dash
    else
      topic.topic_name
    end
  end

  # Get authorization from permissions.
  def authorization
    authorization = 'participant'
    #if the pariticpant cannot submit assignments, but can review them, and take quiz, then they are authorized as readers
    authorization = 'reader' if !can_submit && can_review && can_take_quiz
    #if the participant can submit assignments but cannot review them or cannot take quiz, they are just a submitter
    authorization = 'submitter' if can_submit && !can_review && !can_take_quiz
    #if the participant can not submit assignment but can review them and also not be able to take quiz, then they are reviewers.
    authorization = 'reviewer' if !can_submit && can_review && !can_take_quiz
    authorization
  end

  # Sort participants based on their id or associated user_name.
  # Make sure there is no duplicated participant in this input array.
  def self.sort_participants(participants, sort_by)
    if sort_by == "id"
      participants.sort_by { |p| p.id }
    elsif sort_by == "name"
      participants.sort_by { |p| p.user.name.downcase }
    else
      raise ArgumentError, "Invalid sort parameter. Please use 'id' or 'name'."
    end
  end

  # Provide export functionality for Assignment Participants and Course Participants
  def self.export(csv, parent_id, options)
    where(parent_id: parent_id).find_each do |part|
      tcsv = []
      user = part.user
      tcsv.push(user.name, user.full_name, user.email) if options['personal_details'] == 'true'
      tcsv.push(user.role.name) if options['role'] == 'true'
      tcsv.push(user.parent.name) if options['parent'] == 'true'
      tcsv.push(user.email_on_submission, user.email_on_review, user.email_on_review_of_review) if options['email_options'] == 'true'
      tcsv.push(part.handle) if options['handle'] == 'true'
      csv << tcsv
    end
  end

  def self.export_fields(options)
    fields = []
    fields.push('name', 'full_name', 'email') if options['personal_details'] == 'true'
    fields.push('role') if options['role'] == 'true'
    fields.push('parent') if options['parent'] == 'true'
    fields.push('email on submission', 'email on review', 'email on metareview') if options['email_options'] == 'true'
    fields.push('handle') if options['handle'] == 'true'
    fields
  end
end