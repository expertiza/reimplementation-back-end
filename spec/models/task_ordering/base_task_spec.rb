# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskOrdering::BaseTask do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_bt",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor BT",
      email: "instructor_bt@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_bt",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student BT",
      email: "student_bt@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "BT Assignment", instructor: instructor) }
  let!(:participant) do
    AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
  end
  let!(:team) { AssignmentTeam.create!(name: "BT Team", parent_id: assignment.id) }
  let!(:teams_participant) { TeamsParticipant.create!(team: team, participant: participant, user: student) }

  subject(:task) do
    TaskOrdering::BaseTask.new(
      assignment: assignment,
      team_participant: teams_participant
    )
  end

  describe '#participant' do
    it 'returns the participant from teams_participant' do
      expect(task.participant).to eq(participant)
    end
  end

  describe '#response_map' do
    it 'raises NotImplementedError' do
      expect { task.response_map }.to raise_error(NotImplementedError)
    end
  end

  describe '#completed?' do
    it 'returns false when response_map is nil' do
      allow(task).to receive(:response_map).and_return(nil)
      expect(task.completed?).to be false
    end
  end

  describe '#ensure_response!' do
    it 'returns nil when response_map is nil' do
      allow(task).to receive(:response_map).and_return(nil)
      expect(task.ensure_response!).to be_nil
    end
  end

  describe '#to_task_hash' do
    let(:review_map) do
        map = ReviewResponseMap.new(
            reviewer_id: participant.id,
            reviewee_id: participant.id,
            reviewed_object_id: assignment.id
        )
        map.save!(validate: false)
        map
    end

    let(:review_task) do
        TaskOrdering::ReviewTask.new(
            assignment: assignment,
            team_participant: teams_participant,
            review_map: review_map
            )
        end

    it 'returns a hash with expected keys' do
        hash = review_task.to_task_hash
        expect(hash).to include(:task_type, :assignment_id, :response_map_id, :response_map_type, :reviewee_id, :team_participant_id)
    end

    it 'sets assignment_id correctly' do
        expect(review_task.to_task_hash[:assignment_id]).to eq(assignment.id)
    end

    it 'sets team_participant_id correctly' do
        expect(review_task.to_task_hash[:team_participant_id]).to eq(teams_participant.id)
    end
end
end