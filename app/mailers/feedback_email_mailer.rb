class FeedbackEmailMailer < ApplicationMailer
  # Initialize the mailer with a ResponseMap and an Assignment
  def initialize(response_map, assignment)
    @response_map = response_map
    @assignment   = assignment
  end

  # Public API method to trigger the email send
  def call
    Mailer.sync_message(create_definition_payload).deliver
  end

  private

  def create_definition_payload
    # find the ResponseMap that created that review
    original_map = ResponseMap.find(@response_map.reviewed_object_id)
    # find the participant who wrote that review
    participant = AssignmentParticipant.find(original_map.reviewer_id)
    user        = User.find(participant.user_id)

    {
      to: user.email,
      body: {
        type:       'Author Feedback',
        name: user.name,
        obj_name:   @assignment.name
      }
    }
  end
end
