# spec/routing/signed_up_teams_routing_spec.rb
require "rails_helper"

RSpec.describe Api::SignedUpTeamsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/signed_up_teams").to route_to("api/signed_up_teams#index")
    end

    it "routes to #show" do
      expect(get: "/api/signed_up_teams/1").to route_to("api/signed_up_teams#show", id: "1")
    end
  end
end

# spec/routing/student_tasks_routing_spec.rb
require "rails_helper"

RSpec.describe Api::StudentTasksController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/student_tasks").to route_to("api/student_tasks#index")
    end

    it "routes to #show" do
      expect(get: "/api/student_tasks/1").to route_to("api/student_tasks#show", id: "1")
    end
  end
end