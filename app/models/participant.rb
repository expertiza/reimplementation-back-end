class Participant < ApplicationRecord
  include Scoring
  include ParticipantsHelper
  
  # the various associations for the model is being made
  #paper trail is used to keep track of the changes that are made to the code (does not affect the codebase in anyway)
  has_paper_trail
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
  has_paper_trail
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
  
  # finds team of the user
  def team
    TeamsUser.find_by(user: user).try(:team)
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
    maps = ResponseMap.where('reviewee_id = ? or reviewer_id = ?', id, id) #finds if the participant is either a reviewer or reviewee of an assignment
    #if that is the case, then association exist and therefore participant cannot be deleted
    raise 'Associations exist for this participant.' unless force || (maps.blank? && team.nil?)

    leave_team(maps) #to delete the participant
  end

  #leave_team method deletes a participant from a team. But, to do so, a team has to be present. 
  #First it checks if team exists and them compares the team user id with the participant user id to delete that participant.
  def leave_team(maps)
    maps && maps.each(&:destroy)
    if team
      team.teams_users.each { |teams_user| teams_user.destroy if teams_user.user_id == id }
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

  # Sort a set of participants based on their user names.
  # Please make sure there is no duplicated participant in this input array.
  # There should be a more beautiful way to handle this, though.  -Yang
  def self.sort_by_name(participants)
    users = []
    participants.each { |p| users << p.user }
    users.sort! { |a, b| a.name.downcase <=> b.name.downcase } # Sort the users based on the name
    participants.sort_by { |p| users.map(&:id).index(p.user_id) }
  end

  # Provide export functionality for Assignment Participants and Course Participants
  def self.export(csv, parent_id, options)
    where(parent_id: parent_id).find_each do |part|
      user = part.user
      tcsv = export_function(parent_id,options)
      csv << tcsv
    end
    fields = export_function(parent_id,options)
    fields
  end
 
  # export function used in self.export - DRY principle
  def export_function(parent_id,options)
    arr=[]
    arr.push('name', 'full name', 'email') if options['personal_details'] == 'true'
    arr.push('role') if options['role'] == 'true'
    arr.push('parent') if options['parent'] == 'true'
    arr.push('email on submission', 'email on review', 'email on metareview') if options['email_options'] == 'true'
    arr.push('handle') if options['handle'] == 'true'
    return arr
  end
end
