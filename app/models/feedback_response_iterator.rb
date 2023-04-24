class FeedbackResponseReportIterator
  def initialize(teams, responses)
    @teams = teams
    @responses = responses
    @current_team = nil
    @current_user = nil
    @current_response = nil
  end

  def each(&block)
    @teams.each do |team|
      @current_team = team
      team.users.each do |user|
        @current_user = user
        @current_response = @responses.find_by(map_id: user.review_response_map_id)
        yield @current_user, @current_response
      end
    end
  end
end