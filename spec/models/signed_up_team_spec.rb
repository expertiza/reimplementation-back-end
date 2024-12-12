require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
    let!(:role) { Role.create!(name: "Professor") }
    let!(:instructor) { Instructor.create!(name: "Ed", password: "sec-Key1", full_name: "Ed Gehringer", email: "efg@ncsu.edu", role_id: role.id) }
    let!(:assignment) { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id) }
    let!(:project_topic) { ProjectTopic.create!(topic_name: "Dummy Topic", assignment_id: assignment.id, max_choosers: 3) }
    let!(:team) { Team.create!(assignment_id: assignment.id) }

    describe '.get_team_id_for_user' do
        let!(:user) { User.create!(name: "Name", password: "password", full_name: "Full Name", email: "email@example.com", mru_directory_path: "/dummy/path", role_id: role.id) }
        let!(:teams_user) { TeamsUser.create!(team_id: team.id, user_id: user.id) }
      
        it 'returns the correct team ID for the given user and assignment' do
          expect(SignedUpTeam.get_team_id_for_user(user.id, assignment.id)).to eq(team.id)
        end
      
        it 'returns nil if the user is not associated with any team for the assignment' do
          other_user = User.create!(name: "Name 2", password: "password", full_name: "Full Name", email: "email@example.com", mru_directory_path: "/dummy/path", role_id: role.id)
          expect(SignedUpTeam.get_team_id_for_user(other_user.id, assignment.id)).to be_nil
        end
    end

    describe '.delete_team_signup_records' do
        let!(:signup1) { SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: false, team_id: team.id) }
        let!(:project_topic_2) { ProjectTopic.create!(topic_name: "Dummy Topic 2", assignment_id: assignment.id, max_choosers: 3) }
        let!(:signup2) { SignedUpTeam.create!(sign_up_topic_id: project_topic_2.id, is_waitlisted: true, team_id: team.id) }
      
        it 'removes all sign-up records for the given team' do
          expect { SignedUpTeam.delete_team_signup_records(team.id) }
            .to change { SignedUpTeam.where(team_id: team.id).count }.by(-2)
        end
    end

    describe '#assign_topic_to_waitlisted_team' do
        let!(:project_topic_2) { ProjectTopic.create!(topic_name: "Dummy Topic 2", assignment_id: assignment.id, max_choosers: 3) }
        let!(:signed_up_team) { SignedUpTeam.create!(sign_up_topic_id: project_topic.id, is_waitlisted: true, team_id: team.id) }
        let!(:signed_up_team_2) { SignedUpTeam.create!(sign_up_topic_id: project_topic_2.id, is_waitlisted: false, team_id: team.id) }

        before do
            allow(ProjectTopic).to receive(:find).with(project_topic_2.id).and_return(project_topic_2)
            allow(project_topic_2).to receive(:drop_team_from_topic)
        end

        it 'reassigns the team to a new topic and marks them as not waitlisted' do
            signed_up_team.assign_topic_to_waitlisted_team(project_topic.id)
            expect(signed_up_team.is_waitlisted).to be_falsey
            expect(project_topic_2).to have_received(:drop_team_from_topic).with(team_id: team.id)
        end
    end
end
