require "rails_helper"

RSpec.describe TeamResponseMapsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/team_response_maps").to route_to("team_response_maps#index")
    end

    it "routes to #show" do
      expect(get: "/team_response_maps/1").to route_to("team_response_maps#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/team_response_maps").to route_to("team_response_maps#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/team_response_maps/1").to route_to("team_response_maps#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/team_response_maps/1").to route_to("team_response_maps#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/team_response_maps/1").to route_to("team_response_maps#destroy", id: "1")
    end
  end
end
