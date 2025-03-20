require 'rails_helper'

RSpec.describe "Courses", type: :request do
  let!(:course) { Course.create(title: "Ruby on Rails", description: "Learn Rails") }

  describe "GET /courses" do
    it "returns a successful response" do
      get courses_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby on Rails")
    end
  end

  describe "GET /courses/:id" do
    context "when the course exists" do
      it "returns the course details" do
        get course_path(course)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Ruby on Rails")
      end
    end

    context "when the course does not exist" do
      it "returns a 404 status" do
        get course_path(id: 999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /courses" do
    context "with valid parameters" do
      it "creates a new course" do
        course_params = { course: { title: "RSpec Testing", description: "Learn RSpec" } }
        expect {
          post courses_path, params: course_params
        }.to change(Course, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "does not create a new course" do
        course_params = { course: { title: "", description: "" } }
        expect {
          post courses_path, params: course_params
        }.not_to change(Course, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /courses/:id" do
    context "with valid parameters" do
      it "updates the course" do
        course_params = { course: { title: "Updated Title" } }
        patch course_path(course), params: course_params
        expect(response).to have_http_status(:ok)
        expect(course.reload.title).to eq("Updated Title")
      end
    end

    context "with invalid parameters" do
      it "does not update the course" do
        course_params = { course: { title: "" } }
        patch course_path(course), params: course_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(course.reload.title).to eq("Ruby on Rails")
      end
    end
  end

  describe "DELETE /courses/:id" do
    it "deletes the course" do
      expect {
        delete course_path(course)
      }.to change(Course, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
