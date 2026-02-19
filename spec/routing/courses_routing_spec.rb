require "rails_helper"

RSpec.describe Api::CoursesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/courses").to route_to("api/courses#index")
    end

    it "routes to #show" do
      expect(get: "/api/courses/1").to route_to("api/courses#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/api/courses").to route_to("api/courses#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/api/courses/1").to route_to("api/courses#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/api/courses/1").to route_to("api/courses#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/api/courses/1").to route_to("api/courses#destroy", id: "1")
    end
  end
end