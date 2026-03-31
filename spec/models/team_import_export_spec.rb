# frozen_string_literal: true

require 'rails_helper'
require 'csv'
require 'tempfile'

RSpec.describe Team, type: :model do
  describe 'team import/export' do
    it 'exports assignment teams with participant id columns' do
      assignment = create(:assignment)
      user_one = create(:user, :student, name: 'student_export_one', full_name: 'Student Export One')
      user_two = create(:user, :student, name: 'student_export_two', full_name: 'Student Export Two')
      participant_one = create(:assignment_participant, assignment: assignment, user: user_one)
      participant_two = create(:assignment_participant, assignment: assignment, user: user_two)
      team = AssignmentTeam.create!(name: 'Export Team', parent_id: assignment.id, type: 'AssignmentTeam')

      expect(team.add_member(participant_one)[:success]).to be(true)
      expect(team.add_member(participant_two)[:success]).to be(true)

      export_payload = Team.with_assignment_context(assignment.id) do
        Export.perform(Team, %w[name participant_1 participant_2 participant_3])
      end
      csv_text = export_payload.first[:contents]

      rows = CSV.parse(csv_text, headers: true)
      exported_row = rows.find { |row| row['name'] == 'Export Team' }

      expect(exported_row).not_to be_nil
      expect(exported_row['participant_1']).to eq(participant_one.id.to_s)
      expect(exported_row['participant_2']).to eq(participant_two.id.to_s)
      expect(exported_row['participant_3']).to be_blank
    end

    it 'imports assignment teams and attaches members from participant id columns' do
      assignment = create(:assignment)
      user_one = create(:user, :student, name: 'student_import_one', full_name: 'Student Import One')
      user_two = create(:user, :student, name: 'student_import_two', full_name: 'Student Import Two')
      participant_one = create(:assignment_participant, assignment: assignment, user: user_one)
      participant_two = create(:assignment_participant, assignment: assignment, user: user_two)

      file = Tempfile.new(['team-import', '.csv'])
      file.write("name,participant_1,participant_2\n")
      file.write("Imported Team,#{participant_one.id},#{participant_two.id}\n")
      file.rewind

      expect do
        Team.with_assignment_context(assignment.id) do
          Team.try_import_records(file.path, nil, true, assignment_id: assignment.id)
        end
      end.to change { AssignmentTeam.where(name: 'Imported Team', parent_id: assignment.id).count }.by(1)

      imported_team = AssignmentTeam.find_by!(name: 'Imported Team', parent_id: assignment.id)
      expect(imported_team.participants).to include(participant_one, participant_two)
    ensure
      file.close!
    end
  end
end
