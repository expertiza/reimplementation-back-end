require "rails_helper"

RSpec.describe TeamsAssignmentController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/team_assignments").to route_to("team_assignments#index")
    end

    it "routes to #show" do
      expect(get: "/team_assignments/1").to route_to("team_assignments#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/team_assignments").to route_to("team_assignments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/team_assignments/1").to route_to("team_assignments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/team_assignments/1").to route_to("team_assignments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/team_assignments/1").to route_to("team_assignments#destroy", id: "1")
    end
  end
end
