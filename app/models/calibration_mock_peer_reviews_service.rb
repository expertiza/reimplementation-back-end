# frozen_string_literal: true

# Creates synthetic student ReviewResponseMaps + submitted Responses + Answers for the same
# calibration team so GET .../calibration_reports can show peer comparison charts without a full review UI.
# Lives under app/models so Zeitwerk always autoloads it (app/services is not on all API-only configs).
class CalibrationMockPeerReviewsService
  MOCK_PEER_NAMES = %w[cal_peer_alice cal_peer_bob cal_peer_carol].freeze

  class << self
    def ensure!(assignment:, calibration_map:, target_questionnaire:)
      return unless assignment && calibration_map && target_questionnaire

      team = calibration_map.reviewee
      return unless team.is_a?(AssignmentTeam)

      scored_items = Item.where(questionnaire_id: target_questionnaire.id).select(&:scored?)
      return if scored_items.empty?

      min_s = target_questionnaire.min_question_score
      max_s = target_questionnaire.max_question_score

      inst = assignment.instructor
      institution_id = inst&.institution_id

      MOCK_PEER_NAMES.each_with_index do |uname, peer_idx|
        user = User.find_or_initialize_by(name: uname)
        if user.new_record?
          user.password = 'mockpeer'
          user.password_confirmation = 'mockpeer'
          user.full_name = "Mock peer #{peer_idx + 1} (#{uname})"
          user.email = "#{uname}@example.com"
          user.role_id = Role::STUDENT
          user.institution_id = institution_id
          user.mru_directory_path = '/tmp'
          user.save!
        end

        participant = AssignmentParticipant.find_or_initialize_by(parent_id: assignment.id, user_id: user.id)
        if participant.new_record?
          participant.type = 'AssignmentParticipant'
          participant.handle = uname
          participant.can_review = true
          participant.can_submit = false
          participant.save!
        end

        smap = ReviewResponseMap.find_or_initialize_by(
          reviewed_object_id: assignment.id,
          reviewer_id: participant.id,
          reviewee_id: team.id
        )
        smap.type = 'ReviewResponseMap'
        smap.for_calibration = false
        smap.save!

        next if peer_response_complete?(smap)

        resp = Response.create!(
          map_id: smap.id,
          is_submitted: true,
          additional_comment: "MOCK PEER #{peer_idx + 1}: auto-generated for calibration comparison."
        )

        scored_items.each_with_index do |item, item_idx|
          base = peer_base_score(peer_idx, max_s, min_s)
          delta = (item_idx % 3) - 1
          ans = [[base + delta, min_s].max, max_s].min
          Answer.create!(
            response_id: resp.id,
            item_id: item.id,
            answer: ans,
            comments: "Mock peer #{peer_idx + 1} score for #{item.txt}"
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error "CalibrationMockPeerReviewsService: #{e.class}: #{e.message}\n#{e.backtrace&.first(15)&.join("\n")}"
    end

    private

    def peer_response_complete?(smap)
      latest = smap.responses.order(:id).last
      latest&.is_submitted && latest.scores.exists?
    end

    # Vary scores so agree / near / disagree buckets are visible vs instructor (usually all max).
    def peer_base_score(peer_idx, max_s, min_s)
      case peer_idx % 3
      when 0 then max_s
      when 1 then [max_s - 1, min_s].max
      else [max_s - 2, min_s].max
      end
    end
  end
end
