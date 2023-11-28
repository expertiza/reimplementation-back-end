require 'uri'
require 'yaml'

class AssignmentParticipant < Participant
  # Removed 'contribution' concept overload comment as it requires a major database restructuring.
  # Also removed alias methods that append 'get_' for better naming.

  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  belongs_to :user
  belongs_to :assignment_team #check with devashish
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  #has_many :response_maps, foreign_key: 'reviewee_id'
  #has_many :quiz_mappings, class_name: 'QuizResponseMap', foreign_key: 'reviewee_id'
  #has_many :quiz_response_maps, foreign_key: 'reviewee_id'
  #has_many :quiz_responses, through: :quiz_response_maps, foreign_key: 'map_id'
  attribute :handle, :string
  validates :handle, presence: true

  # Removed obsolete attr_accessors and simplified methods for readability.
  #this method
  def dir_path
    assignment&.directory_path # Use safe navigation operator for assignment to avoid nil errors.
  end

  # all the participants in this assignment who have reviewed the team where this participant belongs
  def reviewers
    # team = self.assignment_team
    #
    # if team.nil?
    #   return [] # Return an empty array if team is nil
    # end
    reviewers = []
    rmaps = ReviewResponseMap.where('reviewee_id = ?', team.id)
    rmaps.each do |rm|
      reviewers.push(AssignmentParticipant.find(rm.reviewer_id))
    end
    reviewers
  end

  #dummy method added to match the functionality of AssignmentTeam
  def set_current_user(_current_user)
    # Removed unnecessary method as commented.
  end
  #copy this participant to a course
  def copy_to_course(course_id)
    CourseParticipant.find_or_create_by(user_id: user_id, parent_id: course_id)
  end

  def feedback
    FeedbackResponseMap.assessments_for(self)
  end

  def reviews
    #ACS Always get assessments for a team
    ReviewResponseMap.assessments_for(team)
  end
  # returns the reviewer of the assignment. Checks the team_reviewing_enabled flag to
  # determine whether this AssignmentParticipant or their team is the reviewer
  def get_reviewer
    assignment.team_reviewing_enabled ? team : self
  end
  # polymorphic twin of method in AssignmentTeam
  # this method is called to check if the current user is this one
  def get_logged_in_reviewer_id(current_user_id)
    current_user_id == id ? id : nil
  end

  # checks if this assignment participant is the currently logged on user, given their user id
  def current_user_is_reviewer?(current_user_id)
    user_id == current_user_id
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

  def files(directory)
    files_list = Dir[directory + '/*']
    files = []

    files_list.each do |file|
      if File.directory?(file)
        dir_files = files(file)
        dir_files.each { |f| files << f }
      end
      files << file
    end
    files
  end

  def team
    AssignmentTeam.team(self)
  end
  # provide import functionality for Assignment Participants
  # if user does not exist, it will be created and added to this assignment



  # define a handle for a new participant
  def set_handle
    self.handle = if user.nil? || user.handle.blank? || AssignmentParticipant.exists?(parent_id: assignment.id, handle: user.handle)
                    user&.name
                  else
                    user.handle
                  end
  end

  def path
    assignment.path + '/' + team.directory_num.to_s
  end
  # zhewei: this is the file path for reviewer to upload files during peer review
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
  # E2147 : Gets duty id of the assignment participant by mapping teams user with help of
  # user_id. Will no longer be needed once teams_user is converted into participant_teams
  def duty_id
    team_user&.duty_id # Use safe navigation operator for team_user
  end

  def team_user
    TeamsUser.find_by(team_id: team.id, user_id: user_id) if team
  end
end
