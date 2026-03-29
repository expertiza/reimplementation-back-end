require_relative 'base_strategy'
require 'csv'

module ReviewMappingStrategies
  class CsvImportStrategy < BaseStrategy
    def initialize(assignment, csv_text)
      super(assignment)
      @csv_text = csv_text
    end

    # Yields reviewer–team pairs based on CSV file
    # CSV expected format: reviewer_email, team_name
    def each_review_pair
      return enum_for(:each_pair) unless block_given?

      CSV.parse(@csv_text, headers: true) do |row|
        reviewer = find_participant_by_email(row['reviewer_email'])
        team     = find_team_by_name(row['team_name'])
        yield reviewer, team if reviewer && team
      end
    end

    private

    def find_participant_by_email(email)
      user = User.find_by(email: email)
      AssignmentParticipant.find_by(user: user, parent_id: @assignment.id)
    end

    def find_team_by_name(name)
      @assignment.teams.find_by(name: name)
    end
  end
end
