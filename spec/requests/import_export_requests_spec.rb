# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe "Import/export requests", type: :request do
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
    context "metadata responses" do
      it "returns metadata for Team" do
        get "/import/Team", params: { assignment_id: 1 }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["mandatory_fields"]).to eq(["name"])
        expect(json["optional_fields"]).to include("participant_1")
        expect(json["available_actions_on_dup"]).to match_array(
          %w[SkipRecordAction UpdateExistingRecordAction ChangeOffendingFieldAction]
        )
      end

      it "returns metadata for ProjectTopic" do
        get "/import/ProjectTopic"

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

      it "returns course import metadata with instructor_name and institution_name" do
        get "/import/Course"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["mandatory_fields"]).to include("name", "directory_path", "instructor_name", "institution_name")
        expect(json["mandatory_fields"]).not_to include("instructor_id", "institution_id")
      end
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

    context "team imports" do
      it "imports teams" do
        student = User.create!(
          name: "student_team_import",
          full_name: "Student Team Import",
          email: "student_team_import@example.com",
          password: "password",
          role: student_role,
          institution: institution
        )
        participant = AssignmentParticipant.create!(user: student, parent_id: assignment.id)
        file = uploaded_csv("name,participant_1\nTeam Alpha,#{participant.id}\n")

        post "/import/Team",
             params: {
               csv_file: file,
               use_headers: true,
               dup_action: "SkipRecordAction",
               assignment_id: assignment.id
             }

        expect(response).to have_http_status(:created)
        imported_team = AssignmentTeam.find_by(name: "Team Alpha", parent_id: assignment.id)
        expect(imported_team).to be_present
        expect(imported_team.participants).to include(participant)
      end
    end

    context "topic imports" do
      it "imports topics" do
        file = uploaded_csv("topic_name,assignment_id\nTopic A,#{assignment.id}\n")

        post "/import/ProjectTopic",
             params: {
               csv_file: file,
               use_headers: true,
               dup_action: "SkipRecordAction"
             }

        expect(response).to have_http_status(:created)
        expect(ProjectTopic.find_by(topic_name: "Topic A", assignment_id: assignment.id)).to be_present
      end
    end

    context "user imports" do
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

    context "course imports" do
      it "imports courses using instructor_name and institution_name" do
        other_institution = Institution.create!(name: "Other School")
        file = uploaded_csv("name,directory_path,info,private,instructor_name,institution_name\nImported Course,imported_course,Imported info,true,teacher,Other School\n")

        post "/import/Course",
             params: {
               csv_file: file,
               use_headers: true
             }

        expect(response).to have_http_status(:created)

        imported_course = Course.find_by(name: "Imported Course")
        expect(imported_course).to be_present
        expect(imported_course.directory_path).to eq("imported_course")
        expect(imported_course.info).to eq("Imported info")
        expect(imported_course.private).to eq(true)
        expect(imported_course.instructor_id).to eq(instructor.id)
        expect(imported_course.institution_id).to eq(other_institution.id)
      end
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
      ProjectTopic.create!(
        topic_name: "Export Topic",
        assignment_id: assignment.id
      )
    end

    context "team exports" do
      it "exports teams" do
        participant_user = User.create!(
          name: "student_team_export",
          full_name: "Student Team Export",
          email: "student_team_export@example.com",
          password: "password",
          role: role,
          institution: institution
        )
        participant_role = Role.find_or_create_by!(name: "Student", parent_id: role.id)
        participant_user.update!(role: participant_role)
        participant = AssignmentParticipant.create!(user: participant_user, parent_id: assignment.id)
        team.add_member(participant)

        post "/export/Team", params: { ordered_fields: %w[name participant_1].to_json, assignment_id: assignment.id }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["file"]).to include("name,participant_1")
        expect(json["file"]).to include("Export Team,#{participant.id}")
      end
    end

    context "topic exports" do
      it "exports topics" do
        post "/export/ProjectTopic", params: { ordered_fields: %w[topic_name assignment_id].to_json }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["file"]).to include("topic_name,assignment_id")
        expect(json["file"]).to include("Export Topic")
      end
    end

    context "course exports" do
      it "exports courses with instructor_name and institution_name" do
        course = Course.create!(
          name: "Export Course",
          directory_path: "export_course",
          info: "Export info",
          private: true,
          instructor: instructor,
          institution: institution
        )

        post "/export/Course", params: { ordered_fields: %w[name directory_path private instructor_name institution_name].to_json }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        exported_file = Array(json["file"]).first

        expect(exported_file["name"]).to eq("Course")
        expect(exported_file["contents"]).to include("name,directory_path,private,instructor_name,institution_name")
        expect(exported_file["contents"]).to include("#{course.name},#{course.directory_path},true,#{instructor.name},#{institution.name}")
      end
    end
  end
end
