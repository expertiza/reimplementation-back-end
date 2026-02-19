require "rails_helper"

RSpec.describe Api::JoinTeamRequestsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/join_team_requests").to route_to(controller: described_class.controller_path, action: "index")
    end

    it "routes to #show" do
      expect(get: "/join_team_requests/1").to route_to(controller: described_class.controller_path, action: "show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/join_team_requests").to route_to(controller: described_class.controller_path, action: "create")
    end

    it "routes to #update via PUT" do
      expect(put: "/join_team_requests/1").to route_to(controller: described_class.controller_path, action: "update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/join_team_requests/1").to route_to(controller: described_class.controller_path, action: "update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/join_team_requests/1").to route_to(controller: described_class.controller_path, action: "destroy", id: "1")
    end
  end
end
