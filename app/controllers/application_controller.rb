class ApplicationController < ActionController::API
  include JwtToken

  # Check if a participant has given authorizations
  def are_needed_authorizations_present?(id, *authorizations)
    participant = Participant.find_by(id: id)
    return false if participant.nil?

    authorization = participant.authorization
    !authorizations.include?(authorization)
  end
end
