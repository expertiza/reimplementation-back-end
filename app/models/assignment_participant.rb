# frozen_string_literal: true

# AssignmentParticipant represents a user participating in a specific assignment.
# It inherits shared behavior from Participant and adds logic specific to assignments.
class AssignmentParticipant < Participant
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  belongs_to :user

  validates :handle, presence: true

  # Sets a unique handle for this participant based on their user's handle or name.
  # Moved to Participant superclass if shared logic applies.
  def set_handle
    self.handle = if user.handle.nil? || user.handle.strip.empty?
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    save
  end

  # Returns the reviewer object. If team reviewing is enabled, return the team.
  # Otherwise, return the participant themselves.
  # Renamed from get_reviewer to follow Ruby naming conventions.
  def reviewer
    assignment.team_reviewing_enabled ? team : self
  end

  # Returns the directory path of the associated assignment.
  def directory_path
    assignment&.directory_path
  end

  # Collects all participants who reviewed this participant’s team.
  def reviewers
    review_maps = ReviewResponseMap.where(reviewee_id: team.id)
    review_maps.map { |map| AssignmentParticipant.find(map.reviewer_id) }
  end

  # Stub method maintained for interface compatibility with other objects like AssignmentTeam.
  def set_current_user(_current_user); end

  # Adds this participant’s user to the given course as a CourseParticipant, if not already added.
  def copy_to_course(course_id)
    # do not assume immediate subclass of Participant, bypass inheritance path
    ::CourseParticipant.find_or_create_by(user_id: user_id, course_id: course_id)
  end


  # Returns all feedback responses for this participant.
  def feedback
    FeedbackResponseMap.assessments_for(self)
  end

  # Returns all peer reviews for this participant’s team.
  def reviews
    ReviewResponseMap.assessments_for(team)
  end

  # Returns this participant’s ID for logging purposes.
  # Renamed for clarity from get_logged_in_reviewer_id.
  def logged_in_reviewer_id(current_user_id)
    id
  end

  # Returns true if the provided user ID matches this participant's user.
  def current_user_is_reviewer?(current_user_id)
    user_id == current_user_id
  end

  # Returns all quiz responses submitted by this participant.
  def quizzes_taken
    QuizResponseMap.assessments_for(self)
  end

  # Returns all metareviews received by this participant.
  def metareviews
    MetareviewResponseMap.assessments_for(self)
  end

  # Returns all teammate reviews received by this participant.
  def teammate_reviews
    TeammateReviewResponseMap.assessments_for(self)
  end

  # Returns all bookmark ratings received by this participant.
  def bookmark_reviews
    BookmarkRatingResponseMap.assessments_for(self)
  end

  # Recursively collects all files from the given directory path.
  def files(directory)
    return [] unless Dir.exist?(directory)

    Dir.glob("#{directory}/**/*").select { |f| File.file?(f) }
  end

  # Returns the full file path of this participant’s team for submission storage.
  def path
    return '' unless assignment && team

    File.join(assignment.path, team.directory_num.to_s)
  end

  # Constructs the path for uploading peer review files.
  def review_file_path(response_map_id = nil, participant = nil)
    if response_map_id.nil?
      return unless participant

      return File.join(assignment.path, "#{participant.name.parameterize(separator: '_')}_review") if participant.team.nil?
    end

    response_map = ResponseMap.find(response_map_id)
    first_user_id = TeamsParticipant.find_by(team_id: response_map.reviewee_id)&.user_id
    participant = Participant.find_by(assignment_id: response_map.reviewed_object_id, user_id: first_user_id)

    return if participant.nil? || participant.team.nil?

    File.join(assignment.path, "#{participant.team.directory_num}_review", response_map_id.to_s)
  end

  # NOTE: Topic-specific stage tracking is not yet supported.
  # These methods rely on SignedUpTeam.topic_id, which does not exist in the current schema.
  # Keeping them commented for potential future implementation tied to topic-based assignments.

  # # Returns the current stage of the assignment for this participant based on topic signup.
  # def current_stage
  #   topic_id = SignedUpTeam.topic_id(assignment_id, user_id)
  #   assignment&.current_stage(topic_id)
  # end
  #
  # # Returns the deadline for the current assignment stage.
  # def stage_deadline
  #   topic_id = SignedUpTeam.topic_id(assignment_id, user_id)
  #   stage = assignment.stage_deadline(topic_id)
  #
  #   return stage unless stage == 'Finished'
  #
  #   if assignment.staggered_deadline?
  #     TopicDueDate.where(parent_id: topic_id).order(due_at: :desc).first&.due_at.to_s
  #   else
  #     assignment.due_dates.last&.due_at.to_s
  #   end
  # end

  # Grants publishing rights by verifying the digital signature.
  def assign_copyright(private_key)
    self.permission_granted = verify_signature(private_key)
    save!
    raise 'Invalid key' unless permission_granted
  end

  # Compares the user’s stored public key with the one derived from the provided private key.
  def verify_signature(private_key)
    user.public_key == OpenSSL::PKey::RSA.new(private_key).public_key.to_pem
  end

  # Imports a participant to an assignment based on a row from a CSV file.
  # If user does not exist, they are created. If already exists, they are reused.
  def self.import(row_hash, _row_header = nil, session:, assignment_id:)
    username = row_hash[:username]&.strip
    raise ArgumentError, 'No username provided.' if username.blank?

    user = User.find_by(name: username)
    if user.nil?
      raise ArgumentError, "Row for '#{username}' does not contain enough fields to create a new user." if row_hash.size < 4

      attributes = ImportFileHelper.define_attributes(row_hash)
      user = ImportFileHelper.create_new_user(attributes, session)
    end

    assignment = Assignment.find_by(id: assignment_id)
    raise ImportError, "Assignment with id #{assignment_id} not found." unless assignment

    return if AssignmentParticipant.exists?(user_id: user.id, assignment_id: assignment.id)

    new_part = AssignmentParticipant.create(user_id: user.id, assignment_id: assignment.id)
    new_part.set_handle
  end
end
