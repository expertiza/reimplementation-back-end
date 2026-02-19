class FeedbackEmailMailer < ApplicationMailer
  # Initialize the mailer with a ResponseMap and an Assignment
  def initialize(response_map, assignment)
    @response_map = response_map
    @assignment   = assignment
  end

  # Public API method to trigger the email send
  def call
    Mailer.sync_message(build_defn).deliver
  end

  private

  def build_defn
    reviewee_id = Response.find(@response_map.reviewee_id)
    participant = AssignmentParticipant.find(reviewee_id)
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
