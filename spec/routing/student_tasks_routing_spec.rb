require "rails_helper"

RSpec.describe StudentTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/student_tasks").to route_to("student_tasks#index")
    end

    it "routes to #show" do
      expect(get: "/student_tasks/1").to route_to("student_tasks#show", id: "1")
    end


    it "routes to #create" do
      expect(post: "/student_tasks").to route_to("student_tasks#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/student_tasks/1").to route_to("student_tasks#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/student_tasks/1").to route_to("student_tasks#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/student_tasks/1").to route_to("student_tasks#destroy", id: "1")
    end
  end
end
