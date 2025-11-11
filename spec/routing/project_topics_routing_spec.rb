require "rails_helper"

RSpec.describe ProjectTopicsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/project_topics").to route_to("project_topics#index")
    end

    it "routes to #show" do
      expect(get: "/project_topics/1").to route_to("project_topics#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/project_topics").to route_to("project_topics#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/project_topics/1").to route_to("project_topics#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/project_topics/1").to route_to("project_topics#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/project_topics/").to route_to("project_topics#destroy")
    end
  end
end