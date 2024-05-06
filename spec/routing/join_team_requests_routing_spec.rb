require "rails_helper"

RSpec.describe JoinTeamRequestsController, type: :routing do
  describe "routing" do
    # Routes to the #index action
    it "routes to #index" do
      expect(get: "/join_team_requests").to route_to("join_team_requests#index")
    end

    # Routes to the #show action with a specific ID
    it "routes to #show" do
      expect(get: "/join_team_requests/1").to route_to("join_team_requests#show", id: "1")
    end

    # Routes to the #create action
    it "routes to #create" do
      expect(post: "/join_team_requests").to route_to("join_team_requests#create")
    end

    # Routes to the #update action via PUT
    it "routes to #update via PUT" do
      expect(put: "/join_team_requests/1").to route_to("join_team_requests#update", id: "1")
    end

    # Routes to the #update action via PATCH
    it "routes to #update via PATCH" do
      expect(patch: "/join_team_requests/1").to route_to("join_team_requests#update", id: "1")
    end

    # Routes to the #destroy action
    it "routes to #destroy" do
      expect(delete: "/join_team_requests/1").to route_to("join_team_requests#destroy", id: "1")
    end
  end
end
