# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

module TaskOrdering
  class QuizTaskTest < ActiveSupport::TestCase

    # ---------------------------------------------------------------------------
    # Helpers — use Structs instead of Minitest::Mock to avoid :nil?, :== issues
    # ---------------------------------------------------------------------------

    FakeQuestionnaire = Struct.new(:id)
    FakeTeamParticipant = Struct.new(:participant_id, :participant, :id)
    FakeReviewMap = Struct.new(:reviewee_id)
    FakeAssignment = Struct.new(:questionnaire) do
      def quiz_questionnaire_for_review_flow
        questionnaire
      end
    end

    def make_assignment(questionnaire: nil)
      FakeAssignment.new(questionnaire)
    end

    def make_team_participant(participant_id: 42)
      FakeTeamParticipant.new(participant_id)
    end

    def make_questionnaire(id: 99)
      FakeQuestionnaire.new(id)
    end

    def make_review_map(reviewee_id: 7)
      FakeReviewMap.new(reviewee_id)
    end

    def build_quiz_task(assignment:, team_participant:, review_map: nil)
      QuizTask.new(
        assignment:       assignment,
        team_participant: team_participant,
        review_map:       review_map
      )
    end

    # ---------------------------------------------------------------------------
    # #task_type
    # ---------------------------------------------------------------------------

    test "task_type returns :quiz" do
      task = build_quiz_task(
        assignment:       make_assignment,
        team_participant: make_team_participant
      )
      assert_equal :quiz, task.task_type
    end

    # ---------------------------------------------------------------------------
    # #questionnaire
    # ---------------------------------------------------------------------------

    test "questionnaire delegates to assignment#quiz_questionnaire_for_review_flow" do
      questionnaire = make_questionnaire(id: 99)
      assignment    = make_assignment(questionnaire:)
      task          = build_quiz_task(assignment:, team_participant: make_team_participant)

      assert_equal questionnaire, task.questionnaire
    end

    test "questionnaire returns nil when assignment has no quiz questionnaire" do
      task = build_quiz_task(
        assignment:       make_assignment(questionnaire: nil),
        team_participant: make_team_participant
      )
      assert_nil task.questionnaire
    end

    # ---------------------------------------------------------------------------
    # #response_map — early returns
    # ---------------------------------------------------------------------------

    test "response_map returns nil when questionnaire is nil" do
      task = build_quiz_task(
        assignment:       make_assignment(questionnaire: nil),
        team_participant: make_team_participant
      )
      assert_nil task.response_map
    end

    test "response_map returns memoized instance on second call" do
      existing_map = QuizResponseMap.new
      task = build_quiz_task(
        assignment:       make_assignment(questionnaire: make_questionnaire),
        team_participant: make_team_participant
      )
      task.instance_variable_set(:@response_map, existing_map)

      assert_same existing_map, task.response_map
    end

    # ---------------------------------------------------------------------------
    # #response_map — finds existing record
    # ---------------------------------------------------------------------------

    test "response_map finds and returns an existing QuizResponseMap" do
      existing = QuizResponseMap.new

      QuizResponseMap.stub(:find_by, existing) do
        task = build_quiz_task(
          assignment:       make_assignment(questionnaire: make_questionnaire(id: 55)),
          team_participant: make_team_participant(participant_id: 3),
          review_map:       make_review_map(reviewee_id: 10)
        )
        assert_same existing, task.response_map
      end
    end

    # ---------------------------------------------------------------------------
    # #response_map — creates new record when none found
    # ---------------------------------------------------------------------------

    test "response_map creates and saves a new QuizResponseMap when none exists" do
      saved    = false
      new_map  = QuizResponseMap.new
      new_map.define_singleton_method(:save!) { |**| saved = true }

      QuizResponseMap.stub(:find_by, nil) do
        QuizResponseMap.stub(:new, new_map) do
          task = build_quiz_task(
            assignment:       make_assignment(questionnaire: make_questionnaire(id: 77)),
            team_participant: make_team_participant(participant_id: 9),
            review_map:       make_review_map(reviewee_id: 5)
          )
          result = task.response_map
          assert_same new_map, result
        end
      end

      assert saved, "expected save! to be called on the new QuizResponseMap"
    end

    # ---------------------------------------------------------------------------
    # #response_map — reviewee_id fallback when review_map is nil
    # ---------------------------------------------------------------------------

    test "response_map uses reviewee_id 0 when review_map is nil" do
      captured_attrs = nil

      QuizResponseMap.stub(:find_by, ->(attrs) { captured_attrs = attrs; nil }) do
        stub_map = QuizResponseMap.new
        stub_map.define_singleton_method(:save!) { |**| }

        QuizResponseMap.stub(:new, stub_map) do
          task = build_quiz_task(
            assignment:       make_assignment(questionnaire: make_questionnaire(id: 88)),
            team_participant: make_team_participant(participant_id: 1),
            review_map:       nil
          )
          task.response_map
        end
      end

      assert_equal 0, captured_attrs[:reviewee_id]
    end

    # ---------------------------------------------------------------------------
    # #response_map — correct attrs passed to find_by
    # ---------------------------------------------------------------------------

    test "response_map passes correct attributes to find_by" do
      captured_attrs = nil

      QuizResponseMap.stub(:find_by, ->(attrs) { captured_attrs = attrs; nil }) do
        stub_map = QuizResponseMap.new
        stub_map.define_singleton_method(:save!) { |**| }

        QuizResponseMap.stub(:new, stub_map) do
          task = build_quiz_task(
            assignment:       make_assignment(questionnaire: make_questionnaire(id: 33)),
            team_participant: make_team_participant(participant_id: 2),
            review_map:       make_review_map(reviewee_id: 8)
          )
          task.response_map
        end
      end

      assert_equal 2,                 captured_attrs[:reviewer_id]
      assert_equal 8,                 captured_attrs[:reviewee_id]
      assert_equal 33,                captured_attrs[:reviewed_object_id]
      assert_equal "QuizResponseMap", captured_attrs[:type]
    end
  end
end