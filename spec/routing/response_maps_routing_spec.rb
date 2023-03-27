require "rails_helper"

RSpec.describe ResponseMapsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/response_maps").to route_to("response_maps#index")
    end

    it "routes to #show" do
      expect(get: "/response_maps/1").to route_to("response_maps#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/response_maps").to route_to("response_maps#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/response_maps/1").to route_to("response_maps#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/response_maps/1").to route_to("response_maps#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/response_maps/1").to route_to("response_maps#destroy", id: "1")
    end
  end
end
