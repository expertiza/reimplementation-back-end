# OLD VERSION BELOW:
class FeedbackResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id'
  belongs_to :review, class_name: 'Response', foreign_key: 'reviewed_object_id'
  belongs_to :reviewer, class_name: 'AssignmentParticipant', dependent: :destroy

  def assignment
    review.map.assignment
  end

  def show_review
    if review
      review.display_as_html
    else
      'No review was performed'
    end
  end

  def get_title
    'Feedback'
  end

  def questionnaire
    assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire')
  end

  def contributor
    review.map.reviewee
  end

  def self.feedback_response_report(id, _type)
    # Example query
    # SELECT distinct reviewer_id FROM response_maps where type = 'FeedbackResponseMap' and
    # reviewed_object_id in (select id from responses where
    # map_id in (select id from response_maps where reviewed_object_id = 722 and type = 'ReviewResponseMap'))
    @review_response_map_ids = ReviewResponseMap.where(['reviewed_object_id = ?', id]).pluck('id')
    teams = AssignmentTeam.includes([:users]).where(parent_id: id)
    # @authors = []
    # teams.each do |team|
    #   team.users.each do |user|
    #     participant = AssignmentParticipant.where(parent_id: id, user_id: user.id).first
    #     @authors << participant
    #   end
    # end
    @authors = get_feedback_authors(id)

    @temp_review_responses = Response.where(['map_id IN (?)', @review_response_map_ids]).order('created_at DESC')
    # we need to pick the latest version of review for each round
    @temp_response_map_ids = []
    if Assignment.find(id).varying_rubrics_by_round?
    #   @all_review_response_ids_round_one = []
    #   @all_review_response_ids_round_two = []
    #   @all_review_response_ids_round_three = []
    #   @temp_review_responses.each do |response|
    #     next if @temp_response_map_ids.include? response.map_id.to_s + response.round.to_s

    #     @temp_response_map_ids << response.map_id.to_s + response.round.to_s
    #     @all_review_response_ids_round_one << response.id if response.round == 1
    #     @all_review_response_ids_round_two << response.id if response.round == 2
    #     @all_review_response_ids_round_three << response.id if response.round == 3
    #   end
      @all_review_response_ids_rounds = varying_rubrics_report(@temp_review_responses, @temp_response_map_ids)
      return authors, @all_review_response_ids_rounds[1], @all_review_response_ids_rounds[2], @all_review_response_ids_rounds[3]
    else
    #   @all_review_response_ids = []
    #   @temp_review_responses.each do |response|
    #     unless @temp_response_map_ids.include? response.map_id
    #       @temp_response_map_ids << response.map_id
    #       @all_review_response_ids << response.id
    #     end
    #   end
      @all_review_response_ids = static_rubrics_report(@temp_review_responses, @temp_response_map_ids)
      return authors, @all_review_response_ids
    end
    # @feedback_response_map_ids = ResponseMap.where(["reviewed_object_id IN (?) and type = ?", @all_review_response_ids, type]).pluck("id")
    # @feedback_responses = Response.where(["map_id IN (?)", @feedback_response_map_ids]).pluck("id")
    # NOTE: ELIMINATING UNNECESSARY CONDITIONAL
    # if Assignment.find(id).varying_rubrics_by_round?
    #   return @authors, @all_review_response_ids_round_one, @all_review_response_ids_round_two, @all_review_response_ids_round_three
    # else
    #   return @authors, @all_review_response_ids
    # end
  end

  # Send emails for author feedback
  # Refactored from email method in response.rb
  def email(defn, _participant, assignment)
    defn[:body][:type] = 'Author Feedback'
    # reviewee is a response, reviewer is a participant
    # we need to track back to find the original reviewer on whose work the author comments
    response_id_for_original_feedback = reviewed_object_id
    response_for_original_feedback = Response.find response_id_for_original_feedback
    response_map_for_original_feedback = ResponseMap.find response_for_original_feedback.map_id
    original_reviewer_participant_id = response_map_for_original_feedback.reviewer_id

    participant = AssignmentParticipant.find(original_reviewer_participant_id)

    defn[:body][:obj_name] = assignment.name

    user = User.find(participant.user_id)

    defn[:to] = user.email
    defn[:body][:first_name] = user.fullname
    Mailer.sync_message(defn).deliver
  end


  private
    # PRIVATE METHODS FOR USE IN SIMPLIFYING self.feedback_response_report
    # Used in the first section of self.feedback_response_report to get the authors of the feedback
    self.get_feedback_authors(id):
      teams = AssignmentTeam.includes([:users]).where(parent_id: id)
      @authors = []
      teams.each do |team|
        team.users.each do |user|
          participant = AssignmentParticipant.where(parent_id: id, user_id: user.id).first
          @authors << participant
        end
      end
      return authors
    end
    # Used in the conditional of self.feedback_response_report to get the rubric reports if the rounds vary
    self.varying_rubrics_report(review_responses, response_map_ids):
      all_review_response_ids_rounds = [1=>[], 2=>[], 3=>[]]
      review_responses.each do |response|
        next if response_map_ids.include? response.map_id.to_s + response.round.to_s
  
        response_map_ids << response.map_id.to_s + response.round.to_s
        all_review_response_ids_rounds[response.round] << response.id
      end
      return all_review_response_ids_rounds
    end
    # Used in the conditional of self.feedback_response_report to get the rubric reports if the rounds do not vary
    self.static_rubrics_report(review_responses, response_map_ids):
      all_review_response_ids = []
      review_responses.each do |response|
        unless response_map_ids.include? response.map_id
          response_map_ids << response.map_id
          all_review_response_ids << response.id
        end
      end
      return all_review_response_ids
    end

end