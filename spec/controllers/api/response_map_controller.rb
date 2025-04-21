require 'rails_helper'

RSpec.describe "Api::V1::ResponseMaps", type: :request do
  controller_class = Api::V1::ResponseMapsController

  before(:each) do
    # Skip authentication callbacks
    controller_class._process_action_callbacks
      .select { |callback| callback.kind == :before }
      .map(&:filter)
      .each do |filter|
        begin
          controller_class.skip_before_action(filter, raise: false)
        rescue => e
          puts "Could not skip filter #{filter}: #{e.message}"
        end
      end
  end

  describe "GET /api/v1/response_maps" do
    it "returns all response maps" do
      instructor_role = Role.create!(name: "Instructor")

      user1 = User.create!(
        name: "Instructor",
        full_name: "Instructor User",
        email: "instructor@example.com",
        password: "password123",
        role: instructor_role
      )

      user2 = User.create!(
        name: "Reviewer",
        full_name: "Reviewer User",
        email: "reviewer@example.com",
        password: "password123",
        role: instructor_role
      )

      user3 = User.create!(
        name: "Reviewee",
        full_name: "Reviewee User",
        email: "reviewee@example.com",
        password: "password123",
        role: instructor_role
      )

      assignment = Assignment.create!(
        name: "Test Assignment",
        directory_path: "test_assignment",
        instructor: user1,
        num_reviews: 1,
        num_reviews_required: 1,
        num_reviews_allowed: 1,
        num_metareviews_required: 1,
        num_metareviews_allowed: 1,
        rounds_of_reviews: 1,
        is_calibrated: false,
        has_badge: false,
        enable_pair_programming: false,
        staggered_deadline: false,
        show_teammate_reviews: false,
        is_coding_assignment: false
      )

      reviewer = Participant.create!(handle: "rev", user: user2, assignment: assignment)
      reviewee = Participant.create!(handle: "ree", user: user3, assignment: assignment)

      ResponseMap.create!(reviewer: reviewer, reviewee: reviewee, assignment: assignment)

      get "/api/v1/response_maps"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end


  describe "GET /api/v1/response_maps/:id" do
    it "returns the requested response map" do
      # Set up same as before
      instructor_role = Role.create!(name: "Instructor")

      user1 = User.create!(
        name: "Instructor",
        full_name: "Instructor User",
        email: "instructor@example.com",
        password: "password123",
        role: instructor_role
      )

      user2 = User.create!(
        name: "Reviewer",
        full_name: "Reviewer User",
        email: "reviewer@example.com",
        password: "password123",
        role: instructor_role
      )

      user3 = User.create!(
        name: "Reviewee",
        full_name: "Reviewee User",
        email: "reviewee@example.com",
        password: "password123",
        role: instructor_role
      )

      assignment = Assignment.create!(
        name: "Test Assignment",
        directory_path: "test_assignment",
        instructor: user1,
        num_reviews: 1,
        num_reviews_required: 1,
        num_reviews_allowed: 1,
        num_metareviews_required: 1,
        num_metareviews_allowed: 1,
        rounds_of_reviews: 1,
        is_calibrated: false,
        has_badge: false,
        enable_pair_programming: false,
        staggered_deadline: false,
        show_teammate_reviews: false,
        is_coding_assignment: false
      )

      reviewer = Participant.create!(handle: "rev", user: user2, assignment: assignment)
      reviewee = Participant.create!(handle: "ree", user: user3, assignment: assignment)

      response_map = ResponseMap.create!(reviewer: reviewer, reviewee: reviewee, assignment: assignment)

      # Use full URL
      get "/api/v1/response_maps/#{response_map.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["id"]).to eq(response_map.id)
    end
  end
end
