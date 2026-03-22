# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe "Import/export entities", type: :request do
  before do
    allow_any_instance_of(JwtToken)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(Authorization)
      .to receive(:authorize)
      .and_return(true)
  end

  def uploaded_csv(contents)
    file = Tempfile.new(["import", ".csv"])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  describe "GET /import/:class" do
    it "returns metadata for Team" do
      get "/import/Team"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["mandatory_fields"]).to include("name", "type", "parent_id")
      expect(json["available_actions_on_dup"]).to match_array(
        %w[SkipRecordAction UpdateExistingRecordAction ChangeOffendingFieldAction]
      )
    end

    it "returns metadata for SignUpTopic" do
      get "/import/SignUpTopic"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["mandatory_fields"]).to include("topic_name", "assignment_id")
      expect(json["available_actions_on_dup"]).to match_array(
        %w[SkipRecordAction UpdateExistingRecordAction ChangeOffendingFieldAction]
      )
    end

    it "returns role_name and institution_name as external fields for User import" do
      Role.create!(name: "Super Administrator", parent_id: nil)

      get "/import/User"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["mandatory_fields"]).to include("name", "email", "password", "full_name")
      expect(json["mandatory_fields"]).not_to include("role_id", "institution_id")
      expect(json["external_fields"]).to include("role_name", "institution_name")
    end
  end

  describe "POST /import/:class" do
    let!(:instructor_role) do
      Role.create!(name: "Instructor", parent_id: nil)
    end

    let!(:student_role) do
      Role.create!(name: "Student", parent_id: instructor_role.id)
    end

    let!(:institution) do
      Institution.create!(name: "NC State")
    end

    let!(:instructor) do
      User.create!(
        name: "teacher",
        full_name: "Teacher Example",
        email: "teacher@example.com",
        password: "password",
        role: instructor_role,
        institution: institution
      )
    end

    before do
      allow_any_instance_of(ImportController)
        .to receive(:current_user)
        .and_return(instructor)
    end

    let!(:assignment) do
      Assignment.create!(
        name: "Import Assignment",
        instructor: instructor
      )
    end

    it "imports teams" do
      file = uploaded_csv("name,parent_id,type\nTeam Alpha,#{assignment.id},AssignmentTeam\n")

      post "/import/Team",
           params: {
             csv_file: file,
             use_headers: true,
             dup_action: "SkipRecordAction"
           }

      expect(response).to have_http_status(:created)
      expect(AssignmentTeam.find_by(name: "Team Alpha", parent_id: assignment.id)).to be_present
    end

    it "imports topics" do
      file = uploaded_csv("topic_name,assignment_id\nTopic A,#{assignment.id}\n")

      post "/import/SignUpTopic",
           params: {
             csv_file: file,
             use_headers: true,
             dup_action: "SkipRecordAction"
           }

      expect(response).to have_http_status(:created)
      expect(SignUpTopic.find_by(topic_name: "Topic A", assignment_id: assignment.id)).to be_present
    end

    it "imports users with parent and institution defaults using role_name" do
      file = uploaded_csv("name,email,password,full_name,role_name\nstudentone,student1@example.com,password,Student One,Student\n")

      post "/import/User",
           params: {
             csv_file: file,
             use_headers: true,
             dup_action: "SkipRecordAction"
           }

      expect(response).to have_http_status(:created)

      imported_user = User.find_by(email: "student1@example.com")
      expect(imported_user).to be_present
      expect(imported_user.parent_id).to eq(instructor.id)
      expect(imported_user.institution_id).to eq(institution.id)
      expect(imported_user.role_id).to eq(student_role.id)
    end

    it "imports users using role_name and institution_name" do
      other_institution = Institution.create!(name: "Other School")
      file = uploaded_csv("name,full_name,email,password,role_name,institution_name\nstudenttwo,Student Two,student2@example.com,password,Student,Other School\n")

      post "/import/User",
           params: {
             csv_file: file,
             use_headers: true,
             dup_action: "SkipRecordAction"
           }

      expect(response).to have_http_status(:created)

      imported_user = User.find_by(email: "student2@example.com")
      expect(imported_user).to be_present
      expect(imported_user.institution_id).to eq(other_institution.id)
      expect(imported_user.parent_id).to eq(instructor.id)
      expect(imported_user.role_id).to eq(student_role.id)
    end
  end

  describe "POST /export/:class" do
    let!(:role) do
      Role.create!(name: "Instructor", parent_id: nil)
    end

    let!(:institution) do
      Institution.create!(name: "NC State")
    end

    let!(:instructor) do
      User.create!(
        name: "teacher_export",
        full_name: "Teacher Export",
        email: "teacher_export@example.com",
        password: "password",
        role: role,
        institution: institution
      )
    end

    let!(:assignment) do
      Assignment.create!(
        name: "Export Assignment",
        instructor: instructor
      )
    end

    let!(:team) do
      AssignmentTeam.create!(
        name: "Export Team",
        parent_id: assignment.id,
        type: "AssignmentTeam"
      )
    end

    let!(:topic) do
      SignUpTopic.create!(
        topic_name: "Export Topic",
        assignment_id: assignment.id
      )
    end

    it "exports teams" do
      post "/export/Team", params: { ordered_fields: %w[name parent_id type].to_json }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["file"]).to include("name,parent_id,type")
      expect(json["file"]).to include("Export Team")
    end

    it "exports topics" do
      post "/export/SignUpTopic", params: { ordered_fields: %w[topic_name assignment_id].to_json }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["file"]).to include("topic_name,assignment_id")
      expect(json["file"]).to include("Export Topic")
    end
  end
end
