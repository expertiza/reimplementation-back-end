# frozen_string_literal: true

module Reports
  # Teammate-review report: for each reviewer, shows how many teammates they
  # have in total, how many they reviewed, and the individual reviewee details.
  #
  # Coordinator runs two reducers into a single shared state:
  #
  #   TeammateReviewReducer — streams TeammateReviewResponseMap rows.
  #     For each row, initializes the reviewer entry if absent and appends
  #     the reviewee to the reviewees list.
  #     Writes to state: { user_id => { ..., reviewed_count:, reviewees: [] } }
  #
  #   TeamSizeReducer — streams TeamsUser rows for the assignment.
  #     For each row, sets teammate_count for that user if they appear in state
  #     (i.e. they are a reviewer). No extra loop needed — writes directly into
  #     the same shared state.
  #     Writes to state: { user_id => { ..., teammate_count: } }
  #
  # Shared state shape (all keys present from initialization, keyed by user_id):
  #   { user_id => { reviewer_id:, user_id:, name:, full_name:,      ← filled by TeammateReviewReducer
  #                      teammate_count:,                             ← filled by TeamSizeReducer
  #                      reviewed_count:,                             ← filled by TeammateReviewReducer
  #                      reviewees: [{ reviewee_id:, name:, full_name: }] } }
  class TeammateReviewReport
    def self.for_assignment(assignment)
      new(assignment)
    end

    def initialize(reportable)
      @reportable = reportable
    end

    def run
      shared_state = Hash.new do |state, user_id|
        state[user_id] = {
          reviewer_id:    nil,
          user_id:        nil,
          name:           nil,
          full_name:      nil,
          teammate_count: 0,
          reviewed_count: 0,
          reviewees:      []
        }
      end
      TeammateReviewReducer.new(@reportable).run(shared_state)
      TeamSizeReducer.new(@reportable).run(shared_state)
      { reviewers: shared_state.values }
    end

    # -----------------------------------------------------------------------
    # Reducer 1 — per-reviewer reviewee details and reviewed count.
    # Streams TeammateReviewResponseMap rows grouped by reviewer_id.
    # -----------------------------------------------------------------------
    class TeammateReviewReducer < BaseReport
      def source
        TeammateReviewResponseMap
          .where(reviewed_object_id: @reportable.id)
          .includes(reviewer: :user, reviewee: :user)
      end

      def state_key_for = ->(map) { map.reviewer&.user_id }

      def initial_state = {}

      def accumulate(state, user_id, map)
        reviewer = map.reviewer
        return unless reviewer

        unless state.key?(user_id)
          state[user_id][:reviewer_id] = reviewer.id
          state[user_id][:user_id]     = reviewer.user_id
          state[user_id][:name]        = reviewer.user&.name
          state[user_id][:full_name]   = reviewer.user&.full_name
        end

        reviewee = map.reviewee
        return unless reviewee

        state[user_id][:reviewees] << {
          reviewee_id: reviewee.id,
          name:        reviewee.user&.name,
          full_name:   reviewee.user&.full_name
        }
        state[user_id][:reviewed_count] += 1
      end
    end

    # -----------------------------------------------------------------------
    # Reducer 2 — per-reviewer teammate count.
    # Streams TeamsUser rows for the assignment. Only updates state for
    # users who are already reviewers (present in shared state).
    # -----------------------------------------------------------------------
    class TeamSizeReducer < BaseReport
      def source
        TeamsUser.for_assignment(@reportable.id).includes(:user)
      end

      def state_key_for = ->(teams_user) { teams_user.user_id }

      def initial_state = {}

      def accumulate(state, user_id, _teams_user)
        # teammate_count is the number of TeamsUser rows for this user's team,
        # which equals the number of teammates (including themselves).
        state[user_id][:teammate_count] += 1 if state.key?(user_id)
      end
    end
  end
end
