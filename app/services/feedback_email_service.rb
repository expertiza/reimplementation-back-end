class FeedbackEmailService
  def initialize(response_map, assignment)
    @response_map = response_map
    @assignment   = assignment
  end

  # public API
  def call
    Mailer.sync_message(build_defn).deliver
  end

  private

  def build_defn
    # find the original review response
    response = Response.find(@response_map.reviewed_object_id)
    # find the ResponseMap that created that review
    original_map = ResponseMap.find(response.map_id)
    # find the participant who wrote that review
    participant = AssignmentParticipant.find(original_map.reviewer_id)
    user        = User.find(participant.user_id)

    {
      to: user.email,
      body: {
        type:       'Author Feedback',
        first_name: user.fullname,
        obj_name:   @assignment.name
      }
    }
  end
end
