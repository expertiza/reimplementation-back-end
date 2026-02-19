require "rails_helper"

RSpec.describe Api::StudentTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/student_tasks").to route_to(controller: described_class.controller_path, action: "index")
    end

    it "routes to #show" do
      expect(get: "/student_tasks/1").to route_to(controller: described_class.controller_path, action: "show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/student_tasks").to route_to(controller: described_class.controller_path, action: "create")
    end

    it "routes to #update via PUT" do
      expect(put: "/student_tasks/1").to route_to(controller: described_class.controller_path, action: "update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/student_tasks/1").to route_to(controller: described_class.controller_path, action: "update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/student_tasks/1").to route_to(controller: described_class.controller_path, action: "destroy", id: "1")
    end
  end
end
