class ApplicationController < ActionController::API

  def locale_for_student
    return true
    #dummy method
  end

  def are_needed_authorizations_present?(id, *authorizations)
    # participant = Participant.find_by(id: id)
    # return false if participant.nil?
    #
    # authorization = participant.authorization
    # !authorizations.include?(authorization)
    return true
    #dummy method
  end

  def undo_link(message)
    # version = Version.where('whodunnit = ?', session[:user].id).last
    # return unless version.try(:created_at) && Time.now.in_time_zone - version.created_at < 5.0
    #
    # link_name = params[:redo] == 'true' ? 'redo' : 'undo'
    # message + "<a href = #{url_for(controller: :versions, action: :revert, id: version.id, redo: !params[:redo])}>#{link_name}</a>"
  end
end
