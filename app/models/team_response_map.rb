class TeamResponseMap < ResponseMap

    def check_team_enabled()
        @m

         if @map.team_reviewing_enabled
        @response = Lock.get_lock(@response, current_user, Lock::DEFAULT_TIMEOUT)
        if @response.nil?
          response_lock_action
          return
        end




    end
end