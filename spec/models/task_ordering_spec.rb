# frozen_string_literal: true
#
# Replaces:
#   spec/models/task_ordering/task_queue_spec.rb
#   spec/models/task_ordering/task_factory_spec.rb
#   spec/models/task_ordering/base_task_spec.rb
#   spec/models/task_ordering/quiz_task_spec.rb
#   spec/models/task_ordering/review_task_spec.rb
#
# The TaskOrdering namespace has been removed. Sequencing logic now lives in
# StudentTasksController private methods and inner classes QuizTaskItem /
# ReviewTaskItem. This file covers equivalent behavior at the correct layer.

require 'rails_helper'

RSpec.describe StudentTasksController, type: :controller do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_tc",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor TC",
      email: "instructor_tc@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_tc",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student TC",
      email: "student_tc@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "TC Assignment", instructor: instructor) }

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let!(:team) { AssignmentTeam.create!(name: "TC Team", parent_id: assignment.id) }

  let!(:teams_participant) do
    TeamsParticipant.create!(team: team, participant: participant, user: student)
  end

  let!(:review_map) do
    ReviewResponseMap.new(
      reviewer_id: participant.id,
      reviewee_id: participant.id,
      reviewed_object_id: assignment.id
    ).tap { |m| m.save!(validate: false) }
  end

  # ===========================================================================
  # ReviewTaskItem — replaces review_task_spec.rb + base_task_spec.rb
  # ===========================================================================
  describe StudentTasksController::ReviewTaskItem do
    subject(:task) do
      described_class.new(
        assignment: assignment,
        team_participant: teams_participant,
        review_map: review_map
      )
    end

    # --- task_type ---

    describe '#task_type' do
      it 'returns :review' do
        expect(task.task_type).to eq(:review)
      end
    end

    # --- response_map ---

    describe '#response_map' do
      it 'returns the review map passed in' do
        expect(task.response_map).to eq(review_map)
      end
    end

    # --- participant (BaseTaskItem contract) ---

    describe '#participant' do
      it 'returns the participant via teams_participant' do
        expect(task.participant).to eq(participant)
      end
    end

    # --- completed? ---

    describe '#completed?' do
      it 'returns false when no submitted response exists' do
        expect(task.completed?).to be false
      end

      it 'returns true when a submitted response exists' do
        Response.create!(map_id: review_map.id, round: 1, is_submitted: true)
        expect(task.completed?).to be true
      end

      it 'returns false when response exists but is not submitted' do
        Response.create!(map_id: review_map.id, round: 1, is_submitted: false)
        expect(task.completed?).to be false
      end
    end

    # --- ensure_response! ---

    describe '#ensure_response!' do
      it 'creates a response if none exists' do
        expect { task.ensure_response! }.to change(Response, :count).by(1)
      end

      it 'does not create duplicate responses' do
        task.ensure_response!
        expect { task.ensure_response! }.not_to change(Response, :count)
      end

      it 'creates response with is_submitted: false' do
        task.ensure_response!
        expect(Response.last.is_submitted).to be false
      end

      it 'creates response with round: 1' do
        task.ensure_response!
        expect(Response.last.round).to eq(1)
      end
    end

    # --- to_h (replaces to_task_hash in old base_task_spec) ---

    describe '#to_h' do
      it 'includes all required contract keys' do
        expect(task.to_h.keys).to include(
          :task_type, :assignment_id, :response_map_id,
          :response_map_type, :reviewee_id, :team_participant_id
        )
      end

      it 'sets task_type correctly' do
        expect(task.to_h[:task_type]).to eq(:review)
      end

      it 'sets assignment_id correctly' do
        expect(task.to_h[:assignment_id]).to eq(assignment.id)
      end

      it 'sets response_map_id correctly' do
        expect(task.to_h[:response_map_id]).to eq(review_map.id)
      end

      it 'sets reviewee_id correctly' do
        expect(task.to_h[:reviewee_id]).to eq(review_map.reviewee_id)
      end

      it 'sets team_participant_id correctly' do
        expect(task.to_h[:team_participant_id]).to eq(teams_participant.id)
      end
    end
  end

  # ===========================================================================
  # QuizTaskItem — replaces quiz_task_spec.rb
  # ===========================================================================
  describe StudentTasksController::QuizTaskItem do
    subject(:task) do
      described_class.new(
        assignment: assignment,
        team_participant: teams_participant,
        review_map: review_map
      )
    end

    # --- task_type ---

    describe '#task_type' do
      it 'returns :quiz' do
        expect(task.task_type).to eq(:quiz)
      end
    end

    # --- response_map ---

    describe '#response_map' do
      context 'when no questionnaire and no existing quiz map' do
        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

        it 'returns nil' do
          expect(task.response_map).to be_nil
        end
      end

      context 'when an existing QuizResponseMap exists for reviewer/reviewee' do
        let!(:existing_quiz_map) do
          QuizResponseMap.new(
            reviewer_id: participant.id,
            reviewee_id: review_map.reviewee_id,
            reviewed_object_id: assignment.id
          ).tap { |m| m.save!(validate: false) }
        end

        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

        it 'returns the existing map' do
          expect(task.response_map).to eq(existing_quiz_map)
        end

        it 'does not create a duplicate map' do
          expect { task.response_map }.not_to change(QuizResponseMap, :count)
        end
      end

      context 'when questionnaire exists and no quiz map yet' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "TC Quiz",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end

        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire) }

        it 'creates and returns a QuizResponseMap' do
          expect(task.response_map).to be_a(QuizResponseMap)
        end

        it 'creates exactly one map' do
          expect { task.response_map }.to change(QuizResponseMap, :count).by(1)
        end

        it 'does not create duplicate maps on repeated calls' do
          task.response_map
          expect { task.response_map }.not_to change(QuizResponseMap, :count)
        end
      end
    end

    # --- completed? ---

    describe '#completed?' do
      context 'when response_map is nil' do
        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

        it 'returns false' do
          expect(task.completed?).to be false
        end
      end

      context 'when quiz map exists with submitted response' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "TC Quiz Done",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          quiz_map = task.response_map
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
        end

        it 'returns true' do
          expect(task.completed?).to be true
        end
      end

      context 'when quiz map exists with unsubmitted response' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "TC Quiz Pending",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          quiz_map = task.response_map
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: false)
        end

        it 'returns false' do
          expect(task.completed?).to be false
        end
      end
    end

    # --- ensure_response! ---

    describe '#ensure_response!' do
      context 'when response_map is nil' do
        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

        it 'returns nil without creating a response' do
          expect(task.ensure_response!).to be_nil
          expect(Response.count).to eq(0)
        end
      end

      context 'when response_map exists' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "TC Quiz Ens",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end

        before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire) }

        it 'creates a response if none exists' do
          task.response_map
          expect { task.ensure_response! }.to change(Response, :count).by(1)
        end

        it 'does not duplicate responses' do
          task.ensure_response!
          expect { task.ensure_response! }.not_to change(Response, :count)
        end

        it 'creates response with is_submitted: false' do
          task.ensure_response!
          expect(Response.last.is_submitted).to be false
        end

        it 'creates response with round: 1' do
          task.ensure_response!
          expect(Response.last.round).to eq(1)
        end
      end
    end

    # --- to_h ---

    describe '#to_h' do
      let!(:questionnaire) do
        QuizQuestionnaire.create!(
          name: "TC Quiz Hash",
          instructor_id: instructor.id,
          min_question_score: 0,
          max_question_score: 5
        )
      end

      before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire) }

      it 'includes all required contract keys' do
        expect(task.to_h.keys).to include(
          :task_type, :assignment_id, :response_map_id,
          :response_map_type, :reviewee_id, :team_participant_id
        )
      end

      it 'sets task_type to :quiz' do
        expect(task.to_h[:task_type]).to eq(:quiz)
      end

      it 'sets assignment_id correctly' do
        expect(task.to_h[:assignment_id]).to eq(assignment.id)
      end

      it 'sets team_participant_id correctly' do
        expect(task.to_h[:team_participant_id]).to eq(teams_participant.id)
      end
    end
  end

  # ===========================================================================
  # Task ordering / queue logic — replaces task_queue_spec.rb
  # Exercises prior_tasks_complete? and build_tasks via private controller methods
  # ===========================================================================
  describe 'task queue ordering (private controller logic)' do
    let(:context) do
      {
        assignment: assignment,
        participant: participant,
        team_participant: teams_participant,
        duty: nil
      }
    end

    describe '#prior_tasks_complete? (private)' do
      it 'returns true when the map is the only task in the queue' do
        tasks = [
          StudentTasksController::ReviewTaskItem.new(
            assignment: assignment,
            team_participant: teams_participant,
            review_map: review_map
          )
        ]
        result = controller.send(:prior_tasks_complete?, tasks, tasks.first)
        expect(result).to be true
      end

      it 'returns false when a prior quiz task is not submitted' do
        quiz_map = QuizResponseMap.new(
          reviewer_id: participant.id,
          reviewee_id: participant.id,
          reviewed_object_id: assignment.id
        )
        quiz_map.save!(validate: false)

        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(
          QuizQuestionnaire.new(id: quiz_map.id)
        )

        quiz_task = StudentTasksController::QuizTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )
        allow(quiz_task).to receive(:response_map).and_return(quiz_map)
        allow(quiz_task).to receive(:completed?).and_return(false)

        review_task = StudentTasksController::ReviewTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )

        tasks = [quiz_task, review_task]
        result = controller.send(:prior_tasks_complete?, tasks, review_task)
        expect(result).to be false
      end

      it 'returns true when the prior quiz task is submitted' do
        quiz_map = QuizResponseMap.new(
          reviewer_id: participant.id,
          reviewee_id: participant.id,
          reviewed_object_id: assignment.id
        )
        quiz_map.save!(validate: false)
        Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)

        quiz_task = StudentTasksController::QuizTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )
        allow(quiz_task).to receive(:response_map).and_return(quiz_map)
        allow(quiz_task).to receive(:completed?).and_return(true)

        review_task = StudentTasksController::ReviewTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )

        tasks = [quiz_task, review_task]
        result = controller.send(:prior_tasks_complete?, tasks, review_task)
        expect(result).to be true
      end
    end

    describe '#find_task_for_map (private)' do
      it 'returns the task matching the given map id' do
        review_task = StudentTasksController::ReviewTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )
        tasks = [review_task]
        found = controller.send(:find_task_for_map, tasks, review_map.id)
        expect(found).to eq(review_task)
      end

      it 'returns nil for an unknown map id' do
        review_task = StudentTasksController::ReviewTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )
        tasks = [review_task]
        found = controller.send(:find_task_for_map, tasks, 99999)
        expect(found).to be_nil
      end

      it 'handles string map ids' do
        review_task = StudentTasksController::ReviewTaskItem.new(
          assignment: assignment,
          team_participant: teams_participant,
          review_map: review_map
        )
        tasks = [review_task]
        found = controller.send(:find_task_for_map, tasks, review_map.id.to_s)
        expect(found).to eq(review_task)
      end
    end
  end

  # ===========================================================================
  # Duty permission helpers — replaces task_factory_spec duty checks
  # ===========================================================================
  describe 'duty_allows_review? (private)' do
    { 'reviewer' => true, 'participant' => true, 'reader' => true, 'mentor' => true,
      'submitter' => false }.each do |name, expected|
      it "returns #{expected} for #{name}" do
        expect(controller.send(:duty_allows_review?, Duty.new(name: name))).to be expected
      end
    end

    it 'returns false for nil' do
      expect(controller.send(:duty_allows_review?, nil)).to be false
    end
  end

  describe 'duty_allows_quiz? (private)' do
    { 'participant' => true, 'reader' => true, 'mentor' => true,
      'reviewer' => false, 'submitter' => false }.each do |name, expected|
      it "returns #{expected} for #{name}" do
        expect(controller.send(:duty_allows_quiz?, Duty.new(name: name))).to be expected
      end
    end

    it 'returns false for nil' do
      expect(controller.send(:duty_allows_quiz?, nil)).to be false
    end
  end

  describe 'duty_allows_submit? (private)' do
    { 'submitter' => true, 'participant' => true, 'mentor' => true,
      'reviewer' => false, 'reader' => false }.each do |name, expected|
      it "returns #{expected} for #{name}" do
        expect(controller.send(:duty_allows_submit?, Duty.new(name: name))).to be expected
      end
    end

    it 'returns false for nil' do
      expect(controller.send(:duty_allows_submit?, nil)).to be false
    end
  end

  # ===========================================================================
  # build_tasks (private) — replaces TaskFactory.build scenarios
  # ===========================================================================
  describe '#build_tasks (private)' do
    let(:base_context) do
      { assignment: assignment, participant: participant, team_participant: teams_participant, duty: nil }
    end

    context 'with no review maps and no quiz questionnaire' do
      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
        ReviewResponseMap.where(reviewer_id: participant.id).destroy_all
      end

      it 'returns an empty array' do
        tasks = controller.send(:build_tasks, base_context)
        expect(tasks).to be_an(Array)
        expect(tasks).to be_empty
      end
    end

    context 'with a review map and reviewer duty' do
      let!(:duty) { Duty.create!(name: 'reviewer', instructor_id: instructor.id) }
      let(:context_with_duty) { base_context.merge(duty: duty) }

      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
      end

      it 'returns a ReviewTaskItem' do
        tasks = controller.send(:build_tasks, context_with_duty)
        expect(tasks.map(&:task_type)).to include(:review)
      end

      it 'does not include a quiz task when quiz is not allowed for reviewer duty' do
        tasks = controller.send(:build_tasks, context_with_duty)
        expect(tasks.map(&:task_type)).not_to include(:quiz)
      end
    end

    context 'with a review map, participant duty, and quiz questionnaire' do
      let!(:duty) { Duty.create!(name: 'participant', instructor_id: instructor.id) }
      let!(:questionnaire) do
        QuizQuestionnaire.create!(
          name: "TC Build Quiz",
          instructor_id: instructor.id,
          min_question_score: 0,
          max_question_score: 5
        )
      end
      let(:context_with_duty) { base_context.merge(duty: duty) }

      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
      end

      it 'places quiz task before review task' do
        tasks = controller.send(:build_tasks, context_with_duty)
        types = tasks.map(&:task_type)
        expect(types.index(:quiz)).to be < types.index(:review)
      end

      it 'returns both quiz and review tasks' do
        tasks = controller.send(:build_tasks, context_with_duty)
        expect(tasks.map(&:task_type)).to include(:quiz, :review)
      end
    end

    context 'with no review maps but quiz questionnaire exists and duty allows quiz' do
      let!(:duty) { Duty.create!(name: 'participant', instructor_id: instructor.id) }
      let!(:questionnaire) do
        QuizQuestionnaire.create!(
          name: "TC Quiz Only",
          instructor_id: instructor.id,
          min_question_score: 0,
          max_question_score: 5
        )
      end
      let(:context_with_duty) { base_context.merge(duty: duty) }

      before do
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
        ReviewResponseMap.where(reviewer_id: participant.id).destroy_all
      end

      it 'returns a quiz-only task list' do
        tasks = controller.send(:build_tasks, context_with_duty)
        expect(tasks.map(&:task_type)).to eq([:quiz])
      end
    end
  end
end