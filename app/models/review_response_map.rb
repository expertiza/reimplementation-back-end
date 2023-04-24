class ReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :contributor, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  # Added for E1973: http://wiki.expertiza.ncsu.edu/index.php/CSC/ECE_517_Fall_2019_-_Project_E1973._Team_Based_Reviewing
  # post initialization function which can be called as part of of initialization sequence
  def after_initialize
    # If an assignment supports team reviews, it is marked in each mapping
    assignment.team_reviewing_enabled
  end

  # Find a review questionnaire associated with this review response map's assignment
  # @param round_number review round number
  # @param  topic_id the topic identifier used to lookup the review questionaire associated with an assignment
  def questionnaire(round_number = nil, topic_id = nil)
    Questionnaire.find(assignment.review_questionnaire_id(round_number, topic_id))
  end

  # getter for title. All response map types have a unique title
  def title
    'Review'
  end

  # destroy this response map and associated maps such as feedback response maps and meta review maps
  def delete
    fmaps = FeedbackResponseMap.where(reviewed_object_id: response.response_id)
    fmaps.each(&:destroy)
    maps = MetareviewResponseMap.where(reviewed_object_id: id)
    maps.each(&:destroy)
    destroy
  end

  # get the fields which should be included in the export operation
  def self.export_fields
    ['contributor', 'reviewed by']
  end

  # export this response map to csv
  # @return csv is the output param the map whould be exported into
  # @param parent_id response maps related to the review responses
  def self.export(csv, parent_id)
    mappings = where(reviewed_object_id: parent_id).to_a
    mappings.sort! { |a, b| a.reviewee.name <=> b.reviewee.name }
    mappings.each do |map|
      csv << [
        map.reviewee.name,
        map.reviewer.name
      ]
    end
  end

  # instantiate response active records based on an imported row of data
  # @param row_hash is the row of data to use in create the associated instances
  # @assignment_id is the associated assignment
  def self.import(row_hash, assignment_id)
    reviewee_user_name = row_hash[:reviewee].to_s
    reviewee_user = User.find_by(name: reviewee_user_name)
    raise ArgumentError, 'Cannot find reviewee user.' unless reviewee_user

    reviewee_participant = AssignmentParticipant.find_by(user_id: reviewee_user.id, parent_id: assignment_id)
    raise ArgumentError, 'Reviewee user is not a participant in this assignment.' unless reviewee_participant

    reviewee_team = AssignmentTeam.team(reviewee_participant)
    if reviewee_team.nil? # lazy team creation: if the reviewee does not have team, create one.
      reviewee_team = AssignmentTeam.create(name: 'Team' + '_' + rand(1000).to_s,
                                            parent_id: assignment_id, type: 'AssignmentTeam')
      #team_user is a variable created locally to create a copy of the TeamsUser object and use it locally in this method.
      team_user = TeamsUser.create(team_id: reviewee_team.id, user_id: reviewee_user.id)
      team_node = TeamNode.create(parent_id: assignment_id, node_object_id: reviewee_team.id)
      TeamUserNode.create(parent_id: team_node.id, node_object_id: team_user.id)
    end
    row_hash[:reviewers].each do |reviewer|
      reviewer_user_name = reviewer.to_s
      reviewer_user = User.find_by(name: reviewer_user_name)
      raise ArgumentError, 'Cannot find reviewer user.' unless reviewer_user
      next if reviewer_user_name.empty?

      reviewer_participant = AssignmentParticipant.find_by(user_id: reviewer_user.id, parent_id: assignment_id)
      raise ArgumentError, 'Reviewer user is not a participant in this assignment.' unless reviewer_participant

      ReviewResponseMap.find_or_create_by(reviewed_object_id: assignment_id,
                                          reviewer_id: reviewer_participant.get_reviewer.id,
                                          reviewee_id: reviewee_team.id,
                                          calibrate_to: false)
    end
  end

  # get the html for the associated response instance
  # @param response instance
  def show_feedback(response)
    return unless self.response.any? && response

    map = FeedbackResponseMap.find_by(reviewed_object_id: response.id)
    map.response.last.display_as_html if map && map.response.any?
  end

  # get all metareview response maps associated with this response map i.e through the Response hierarchy
  def metareview_response_maps
    responses = Response.where(map_id: id)
    metareview_list = []
    responses.each do |response|
      metareview_response_maps = MetareviewResponseMap.where(reviewed_object_id: response.id)
      metareview_response_maps.each { |metareview_response_map| metareview_list << metareview_response_map }
    end
    metareview_list
  end


  # @@return the reviewer of the response, either a participant or a team
  def reviewer
    ReviewResponseMap.reviewer_by_id(assignment.id, reviewer_id)
  end

  # gets the reviewer of the response, given the assignment and the reviewer id
  # the assignment is used to determine if the reviewer is a participant or a team
  # @param assignment identifier
  # @param reviewer identifer
  # @return Participant or Team
  def self.reviewer_by_id(assignment_id, reviewer_id)
    assignment = Assignment.find(assignment_id)
    if assignment.team_reviewing_enabled
      return AssignmentTeam.find(reviewer_id)
    else
      return AssignmentParticipant.find(reviewer_id)
    end
  end

  # wrap latest version of responses in each response map, together with the questionnaire_id
  # will be used to display the reviewer summary
  def self.final_versions_from_reviewer(assignment_id, reviewer_id)
    reviewer = reviewer_by_id(assignment_id, reviewer_id)
    maps = ReviewResponseMap.where(reviewer_id: reviewer_id)
    assignment = Assignment.find(reviewer.parent_id)
    prepare_final_review_versions(assignment, maps)
  end

  # get a review response report a given review object. This provides ability to see all feedback response for a review
  # @param id is the review object id
  def self.review_response_report(id, assignment, type, review_user)
    # This is not a search, so find all reviewers for this assignment
    response_maps_with_distinct_participant_id =
      ResponseMap.select('DISTINCT reviewer_id').where('reviewed_object_id = ? and type = ? and calibrate_to = ?', id, type, 0)

    # Create an iterator object
    iterator = ReviewResponseReportIterator.new(response_maps_with_distinct_participant_id, assignment, type)

    # Yield the reviewers to the block
    iterator.each do |reviewer|
      yield reviewer
    end
  end

  # Send emails for review response
  # @param email_command is a command object which will be fully hydrated in this function an dpassed to the mailer service
  # email_command should be initialized to a nested hash which invoking this function {body: {}}
  # @param assignment is the assignment instance for which the email is related to
  def send_email(email_command, assignment)
    email_command[:body][:type] = 'Peer Review'
    AssignmentTeam.find(reviewee_id).users.each do |user|
      email_command[:body][:obj_name] = assignment.name
      email_command[:body][:first_name] = User.find(user.id).fullname
      email_command[:to] = User.find(user.id).email
      Mailer.sync_message(email_command).deliver_now
    end
  end

  # collects latest versions of all responses for a given assignment and set of response maps
  # @param assignment - instance of assignment used for doing response lookups
  # @param maps - set of response maps associated with the assignment
  # @return aggregated structure containing latest version of review response
  def self.prepare_final_review_versions(assignment, maps)
    review_final_versions = {}
    rounds_num = assignment.rounds_of_reviews
    if rounds_num && (rounds_num > 1)
      (1..rounds_num).each do |round|
        prepare_review_response(assignment, maps, review_final_versions, round)
      end
    else
      prepare_review_response(assignment, maps, review_final_versions, nil)
    end
    review_final_versions
  end

  # preprocessor used for merging data from Response, Assignment, & ResponseMaps to create structure for the review report
  # @return merged hash structure which contains pertinent details for the report. see review_response_report function
  def self.prepare_review_response(assignment, maps, review_final_versions, round)
    symbol = if round.nil?
               :review
             else
               ('review round' + ' ' + round.to_s).to_sym
             end
    review_final_versions[symbol] = {}
    review_final_versions[symbol][:questionnaire_id] = assignment.review_questionnaire_id(round)
    response_ids = []
    maps.each do |map|
      where_map = { map_id: map.id }
      where_map[:round] = round unless round.nil?
      responses = Response.where(where_map)
      response_ids << responses.last.id unless responses.empty?
    end
    review_final_versions[symbol][:response_ids] = response_ids
  end
end
