# frozen_string_literal: true

class RubricUpdateMailer < ApplicationMailer
  def review_redo_notification
    @response_map = params[:response_map]
    @assignment = params[:assignment]
    @reviewer = @response_map.reviewer
    @reviewee = @response_map.reviewee

    mail(
      to: @reviewer.user.email,
      subject: "Please redo your review for #{@assignment.name}"
    )
  end
end
