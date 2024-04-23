class ApplicationController < ActionController::API
  include JwtToken
  def are_needed_authorizations_present?(id, *authorizations)
    participant = Participant.find_by(id: id)
    return false if participant.nil?

    authorization = participant.authorization
    !authorizations.include?(authorization)
  end

  def current_user_id?(user_id)
    current_user.try(:id) == user_id
  end
end
