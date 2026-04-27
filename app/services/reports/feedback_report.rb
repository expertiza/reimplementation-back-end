# frozen_string_literal: true

module Reports
  # Author-feedback report: shows the latest review response IDs that received
  # author feedback, bucketed by round for varying-rubric assignments.
  #
  # Pipeline:
  #   source   — Responses on ReviewResponseMaps for this assignment,
  #              ordered newest-first so the first occurrence per (map, round)
  #              is the latest revision.
  #   grouper  — [map_id, round]: deduplication key (one response per map per round)
  #   accumulate — skips duplicates; buckets response IDs by round
  #   finalize — fetches authors (one query), returns shaped hash
  class FeedbackReport < BaseReport
    def source
      Response
        .joins(:response_map)
        .where(response_maps: { type: 'ReviewResponseMap', reviewed_object_id: @assignment.id })
        .order(created_at: :desc)
    end

    def grouper = ->(r) { [r.map_id, r.round] }

    def initial_state
      { seen: Set.new, round_1: [], round_2: [], round_3: [], all: [] }
    end

    def accumulate(state, key, response)
      return if state[:seen].include?(key)

      state[:seen].add(key)

      if @assignment.varying_rubrics_by_round?
        case response.round
        when 1 then state[:round_1] << response.id
        when 2 then state[:round_2] << response.id
        when 3 then state[:round_3] << response.id
        end
      else
        state[:all] << response.id
      end
    end

    def finalize(state)
      authors = fetch_authors

      if @assignment.varying_rubrics_by_round?
        {
          authors: authors.map { |a| format_participant(a) },
          review_response_ids: {
            round_1: state[:round_1],
            round_2: state[:round_2],
            round_3: state[:round_3]
          }
        }
      else
        {
          authors: authors.map { |a| format_participant(a) },
          review_response_ids: state[:all]
        }
      end
    end

    private

    def fetch_authors
      teams = AssignmentTeam.includes(:users).where(parent_id: @assignment.id)
      teams.flat_map do |team|
        team.users.filter_map do |user|
          AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: user.id)
        end
      end
    end

    def format_participant(p)
      return {} unless p

      {
        id:        p.id,
        user_id:   p.user_id,
        name:      p.user&.name,
        full_name: p.user&.full_name
      }
    end
  end
end
