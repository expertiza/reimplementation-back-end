require 'uri'
require 'yaml'

class AssignmentParticipant < Participant

  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  belongs_to :user
  belongs_to :assignment_team
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  attribute :handle, :string
  validates :handle, presence: true

  def dir_path
    # Retrieves the directory path from the 'assignment' object if it exists, using the safe navigation operator to handle potential nil values.
    assignment&.directory_path
  end

  # all the participants in this assignment who have reviewed the team where this participant belongs
  def reviewers
    reviewers = [] # Initialize an empty array to store reviewers.
    # Fetch ReviewResponseMap records where the reviewee_id matches the team's ID.
    rmaps = ReviewResponseMap.where('reviewee_id = ?', team.id)
    # Iterate through each ReviewResponseMap.
    rmaps.each do |rm|
      # Find the AssignmentParticipant using the reviewer_id from the ReviewResponseMap
      # and add it to the 'reviewers' array.
      reviewers.push(AssignmentParticipant.find(rm.reviewer_id))
    end
    reviewers # Return the array containing the found reviewers.
  end

  #dummy method added to match the functionality of AssignmentTeam
  def set_current_user(_current_user)
    # Removed unnecessary method as commented.
  end
  #copy this participant to a course
  def copy_to_course(course_id)
    # Find or create a CourseParticipant by user_id and parent_id (course_id).
    CourseParticipant.find_or_create_by(user_id: user_id, parent_id: course_id)
  end

  def feedback
    # Retrieve assessments related to 'self' (likely an instance of a model) using FeedbackResponseMap.
    FeedbackResponseMap.assessments_for(self)
  end

  def reviews
    # Retrieve assessments related to the 'team' using ReviewResponseMap.
    ReviewResponseMap.assessments_for(team)
  end
  # returns the reviewer of the assignment. Checks the team_reviewing_enabled flag to

  # determine whether this AssignmentParticipant or their team is the reviewer
  def get_reviewer
    assignment.team_reviewing_enabled ? team : self
  end

  # this method is called to check if the current user is this one
  def get_logged_in_reviewer_id(current_user_id)
    current_user_id == id ? id : nil
  end
  # Checks if the provided current_user_id matches the id of the current object.
  # Returns the id if they match, otherwise returns nil.

  # Checks if the user_id of this assignment participant matches the provided current_user_id.
  def current_user_is_reviewer?(current_user_id)
    user_id == current_user_id
  end
  # Returns true if they match, indicating that the current user is the reviewer; otherwise, returns false.


  def quizzes_taken
    # Retrieve assessments related to 'self' (likely an instance of a model) using QuizResponseMap.
    QuizResponseMap.assessments_for(self)
  end

  def metareviews
    # Retrieve assessments related to 'self' using MetareviewResponseMap.
    MetareviewResponseMap.assessments_for(self)
  end

  def teammate_reviews
    # Retrieve assessments related to 'self' using TeammateReviewResponseMap.
    TeammateReviewResponseMap.assessments_for(self)
  end

  def bookmark_reviews
    # Retrieve assessments related to 'self' using BookmarkRatingResponseMap.
    BookmarkRatingResponseMap.assessments_for(self)
  end

  def files(directory)
    files_list = Dir[directory + '/*'] # Lists all files and directories in the given 'directory'.
    files = [] # Initialize an empty array to store files.

    files_list.each do |file|
      if File.directory?(file) # Checks if the current 'file' is a directory.
        dir_files = files(file) # Recursively calls 'files' method for subdirectories.
        dir_files.each { |f| files << f } # Appends files from subdirectories to the 'files' array.
      end
      files << file # Appends the current file to the 'files' array.
    end
    files # Returns the list of files in the 'directory' and its subdirectories.
  end

  def team
    AssignmentTeam.team(self)
  end

  # define a handle for a new participant
  def set_handle
    self.handle = if user.nil? || user.handle.blank? || AssignmentParticipant.exists?(parent_id: assignment.id, handle: user.handle)
                    user&.name # Set handle to user's name if user is nil, has a blank handle, or if a handle conflict exists.
                  else
                    user.handle # Set handle to user's handle otherwise.
                  end
  end


  def path
    # Constructs a path by concatenating assignment's path with team's directory number.
    assignment.path + '/' + team.directory_num.to_s
  end

  def review_file_path(response_map_id = nil, participant = nil)
    return nil if response_map_id.nil? && participant.nil? # Check if both arguments are nil, return nil if so.

    response_map = ResponseMap.find_by(id: response_map_id) # Find the response_map using the provided response_map_id.
    return nil if response_map.nil? # Return nil if response_map is not found.

    # Retrieve the user ID of the first user associated with the team.
    first_user_id = TeamsUser.find_by(team_id: response_map.reviewee_id)&.user_id

    # Find the participant using the reviewed_object_id and the first_user_id.
    participant = Participant.find_by(parent_id: response_map.reviewed_object_id, user_id: first_user_id)
    return nil if participant.nil? # Return nil if participant is not found.

    # Construct and return the review file path based on assignment's path, team's directory number, and response_map_id.
    "#{assignment.path}/#{participant.team.directory_num}_review/#{response_map_id}"
  end


  def current_stage
    topic_id = SignedUpTeam.topic_id(parent_id, user_id) # Get the topic_id using parent_id and user_id.
    assignment&.current_stage(topic_id) # Retrieve the current stage from the assignment based on the obtained topic_id.
  end

  def stage_deadline
    topic_id = SignedUpTeam.topic_id(parent_id, user_id) # Get the topic_id using parent_id and user_id.
    stage = assignment&.stage_deadline(topic_id) # Retrieve the stage deadline using safe navigation operator for assignment

    if stage == 'Finished'
      # If the stage is 'Finished':
      due_at = if assignment.staggered_deadline
                 TopicDueDate.find_by(parent_id: topic_id)&.last&.due_at # Retrieve the last due date for the topic if staggered deadlines are enabled
               else
                 assignment.due_dates.last&.due_at # Retrieve the last overall assignment due date
               end
      return due_at&.to_s # Return the due date in string format if available
    end

    stage # Return the stage if it's not 'Finished'
  end


  def duty_id
    team_user&.duty_id # Retrieve the duty_id from the team_user using safe navigation
  end

  def team_user
    TeamsUser.find_by(team_id: team.id, user_id: user_id) if team # Find TeamsUser if team is present
  end
end
