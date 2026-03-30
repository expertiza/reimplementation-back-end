# frozen_string_literal: true

# Builds { hyperlinks: [], files: [] } for a calibration participant's team submission,
# aligned with how SubmittedContent / AssignmentTeam expose artifacts.
class CalibrationSubmittedContent
  def self.for_participant(participant)
    return { hyperlinks: [], files: [] } unless participant.is_a?(AssignmentParticipant)

    team = AssignmentTeam.team(participant)
    hyperlinks = safe_hyperlinks(team)

    files = []
    if team&.id
      begin
        SubmissionRecord.where(team_id: team.id, assignment_id: participant.parent_id)
                        .where(record_type: 'file')
                        .find_each { |rec| files << rec.content if rec.content.present? }
      rescue StandardError => e
        Rails.logger.warn("[CalibrationSubmittedContent] files for team_id=#{team.id}: #{e.class}: #{e.message}")
        files = []
      end
    end

    { hyperlinks: hyperlinks, files: files.uniq }
  end

  def self.safe_hyperlinks(team)
    return [] unless team&.respond_to?(:hyperlinks)

    Array(team.hyperlinks).compact
  rescue StandardError => e
    Rails.logger.warn("[CalibrationSubmittedContent] hyperlinks: #{e.class}: #{e.message}")
    []
  end
  private_class_method :safe_hyperlinks
end
