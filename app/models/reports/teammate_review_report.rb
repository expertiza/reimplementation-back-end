# frozen_string_literal: true

module Reports
  # Teammate-review report: returns one row per reviewer showing which teammates
  # they reviewed, whether a response was submitted, and when it was last updated.
  #
  # Output:
  #   {
  #     reviews: [
  #       {
  #         id: Integer,                        # TeammateReviewResponseMap id
  #         reviewer: {
  #           id: Integer,                      # AssignmentParticipant id
  #           user: { id: Integer, name: String }
  #         },
  #         reviewee: {
  #           id: Integer,                      # AssignmentParticipant id
  #           user: { id: Integer, name: String }
  #         },
  #         submitted: Boolean,
  #         last_reviewed_at: String | nil      # ISO8601 timestamp or nil
  #       }
  #     ]
  #   }
  class TeammateReviewReport
    MAP_JSON_OPTIONS = {
      only: [:id],
      include: {
        reviewer: {
          only: [:id],
          include: { user: { only: %i[id name] } }
        },
        reviewee: {
          only: [:id],
          include: { user: { only: %i[id name] } }
        },
        responses: {
          only: %i[id is_submitted additional_comment],
          include: {
            scores: {
              only: %i[id answer comments],
              include: { item: { only: %i[id txt weight] } }
            }
          }
        }
      }
    }.freeze

    def self.for_assignment(assignment)
      new(assignment)
    end

    def initialize(reportable)
      @reportable = reportable
    end

    def run
      maps = TeammateReviewResponseMap
               .where(reviewed_object_id: @reportable.id)
               .includes(reviewer: :user, reviewee: :user, responses: { scores: :item })

      # Batch-load team names for all reviewer participants to avoid N+1.
      reviewer_ids = maps.map(&:reviewer_id).uniq
      tp_rows = TeamsParticipant.where(participant_id: reviewer_ids).includes(:team)
      team_by_participant = tp_rows.each_with_object({}) do |tp, h|
        h[tp.participant_id] = tp.team&.name
      end

      reviews = maps.map do |map|
        latest = map.responses.select(&:is_submitted).max_by(&:updated_at)
        map.as_json(MAP_JSON_OPTIONS).merge(
          team_name:        team_by_participant[map.reviewer_id],
          submitted:        latest.present?,
          last_reviewed_at: latest&.updated_at&.iso8601
        )
      end

      { reviews: reviews }
    end
  end
end
