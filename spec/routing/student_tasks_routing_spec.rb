# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/student_tasks").to route_to("student_tasks#index")
    end

    it "routes to #show" do
      expect(get: "/student_tasks/1").to route_to("student_tasks#show", id: "1")
    end

    it "routes to #list" do
      expect(get: "/student_tasks/list").to route_to("student_tasks#list")
    end

    it "routes to #view" do
      expect(get: "/student_tasks/view").to route_to("student_tasks#view")
    end

    it "routes to #request_revision" do
      expect(post: "/student_tasks/1/request_revision").to route_to("student_tasks#request_revision", id: "1")
    end
  end
end
