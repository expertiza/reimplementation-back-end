# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskOrdering::QuizTask do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_qt",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor QT",
      email: "instructor_qt@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_qt",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student QT",
      email: "student_qt@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "QT Assignment", instructor: instructor) }
  let!(:participant) do
    AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
  end
  let!(:team) { AssignmentTeam.create!(name: "QT Team", parent_id: assignment.id) }
  let!(:teams_participant) { TeamsParticipant.create!(team: team, participant: participant, user: student) }
  let!(:review_map) do
  map = ReviewResponseMap.new(
    reviewer_id: participant.id,
    reviewee_id: participant.id,
    reviewed_object_id: assignment.id
  )
  map.save!(validate: false)
  map
end

  subject(:task) do
    TaskOrdering::QuizTask.new(
      assignment: assignment,
      team_participant: teams_participant,
      review_map: review_map
    )
  end

  describe '#task_type' do
    it 'returns :quiz' do
      expect(task.task_type).to eq(:quiz)
    end
  end

  describe '#response_map' do
    context 'when assignment has no quiz questionnaire' do
      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
      end

      it 'returns nil' do
        expect(task.response_map).to be_nil
      end
    end

    context 'when assignment has a quiz questionnaire' do
      let!(:questionnaire) do
        QuizQuestionnaire.create!(
          name: "QT Quiz",
          instructor_id: instructor.id,
          min_question_score: 0,
          max_question_score: 5
        )
      end

      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
      end

      it 'returns or creates a QuizResponseMap' do
        map = task.response_map
        expect(map).to be_a(QuizResponseMap)
      end

      it 'does not create duplicate maps on repeated calls' do
        task.response_map
        expect { task.response_map }.not_to change(QuizResponseMap, :count)
      end
    end
  end

  describe '#completed?' do
    context 'when no quiz questionnaire' do
      before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

      it 'returns false' do
        expect(task.completed?).to be false
      end
    end
  end
end