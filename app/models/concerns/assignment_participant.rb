require 'uri'
require 'yaml'

class AssignmentParticipant < Participant
  # Removed 'contribution' concept overload comment as it requires a major database restructuring.
  # Also removed alias methods that append 'get_' for better naming.

  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  belongs_to :user

  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :response_maps, foreign_key: 'reviewee_id'
  has_many :quiz_mappings, class_name: 'QuizResponseMap', foreign_key: 'reviewee_id'
  has_many :quiz_response_maps, foreign_key: 'reviewee_id'
  has_many :quiz_responses, through: :quiz_response_maps, foreign_key: 'map_id'

  validates :handle, presence: true

  # Removed obsolete attr_accessors and simplified methods for readability.

  def dir_path
    assignment&.directory_path # Use safe navigation operator for assignment to avoid nil errors.
  end

  def reviewers
    # Simplified and improved code using map.
    ReviewResponseMap.where('reviewee_id = ?', team.id).map { |rm| AssignmentParticipant.find(rm.reviewer_id) }
  end

  def set_current_user(_current_user)
    # Removed unnecessary method as commented.
  end

  def copy_to_course(course_id)
    CourseParticipant.find_or_create_by(user_id: user_id, parent_id: course_id)
  end

  def feedback
    FeedbackResponseMap.assessments_for(self)
  end

  def reviews
    ReviewResponseMap.assessments_for(team)
  end

  def get_reviewer
    assignment.team_reviewing_enabled ? team : self
  end

  def get_logged_in_reviewer_id(current_user_id)
    current_user_id == id ? id : nil
  end

  def quizzes_taken
    QuizResponseMap.assessments_for(self)
  end

  def metareviews
    MetareviewResponseMap.assessments_for(self)
  end

  def teammate_reviews
    TeammateReviewResponseMap.assessments_for(self)
  end

  def bookmark_reviews
    BookmarkRatingResponseMap.assessments_for(self)
  end

  def team
    AssignmentTeam.team(self)
  end

  def self.import(row_hash, _row_header = nil, session, id)
    raise ArgumentError, 'No user id has been specified.' if row_hash.empty?

    user = User.find_by(name: row_hash[:name])

    if user.nil?
      raise ArgumentError, "The record containing #{row_hash[:name]} does not have enough items." if row_hash.length < 4

      attributes = ImportFileHelper.define_attributes(row_hash)
      user = ImportFileHelper.create_new_user(attributes, session)
    end

    raise ImportError, "The assignment with id \"#{id}\" was not found." if Assignment.find_by(id: id).nil?

    return if AssignmentParticipant.exists?(user_id: user.id, parent_id: id)

    new_part = AssignmentParticipant.create(user_id: user.id, parent_id: id)
    new_part.set_handle
  end

  def assign_copyright(private_key)
    self.permission_granted = verify_digital_signature(private_key)
    save
    raise 'Invalid key' unless permission_granted
  end

  def verify_digital_signature(private_key)
    user.public_key == OpenSSL::PKey::RSA.new(private_key).public_key.to_pem
  end

  def set_handle
    self.handle = if user.handle.blank? || AssignmentParticipant.exists?(parent_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    save!
  end

  def path
    "#{assignment.path}/#{team.directory_num}"
  end

  def review_file_path(response_map_id = nil, participant = nil)
    return nil if response_map_id.nil? && participant.nil?

    response_map = ResponseMap.find_by(id: response_map_id)
    return nil if response_map.nil?

    first_user_id = TeamsUser.find_by(team_id: response_map.reviewee_id)&.user_id
    participant = Participant.find_by(parent_id: response_map.reviewed_object_id, user_id: first_user_id)
    return nil if participant.nil?

    "#{assignment.path}/#{participant.team.directory_num}_review/#{response_map_id}"
  end

  def current_stage
    topic_id = SignedUpTeam.topic_id(parent_id, user_id)
    assignment&.current_stage(topic_id) # Use safe navigation operator for assignment
  end

  def stage_deadline
    topic_id = SignedUpTeam.topic_id(parent_id, user_id)
    stage = assignment&.stage_deadline(topic_id) # Use safe navigation operator for assignment
    if stage == 'Finished'
      due_at = assignment.staggered_deadline ? TopicDueDate.find_by(parent_id: topic_id)&.last&.due_at : assignment.due_dates.last&.due_at
      return due_at&.to_s
    end
    stage
  end

  def duty_id
    team_user&.duty_id # Use safe navigation operator for team_user
  end

  def team_user
    TeamsUser.find_by(team_id: team.id, user_id: user_id) if team
  end
end
