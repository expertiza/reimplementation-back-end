require "rails_helper"

RSpec.describe Api::StudentTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/student_tasks").to route_to("api/student_tasks#index")
    end

    it "routes to #show" do
      expect(get: "/api/student_tasks/1").to route_to("api/student_tasks#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/api/student_tasks").to route_to("api/student_tasks#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/api/student_tasks/1").to route_to("api/student_tasks#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/api/student_tasks/1").to route_to("api/student_tasks#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/api/student_tasks/1").to route_to("api/student_tasks#destroy", id: "1")
    end
  end
end
