require 'rails_helper'

RSpec.describe Team, type: :model do
  let(:role) { Role.create!(name: 'Instructor') }
  let(:instructor) do
    User.create!(
      name: 'instructor1',
      full_name: 'Instructor One',
      email: 'instructor1@example.com',
      password: 'password',
      role: role
    )
  end
  let(:assignment) { Assignment.create!(title: 'Test Assignment', instructor: instructor) }
  let(:user_parent) do
    User.create!(
      name: 'parent_user',
      full_name: 'Parent User',
      email: 'parent@example.com',
      password: 'password',
      role: role
    )
  end

  before do
    $redis = double("Redis", get: '')
  end

  describe '#parent_entity_type' do
    it 'returns "Assignment" for an AssignmentTeam' do
      team = AssignmentTeam.new
      expect(team.parent_entity_type).to eq('Assignment')
    end
  end

  describe '#find_parent_entity' do
    it 'returns the parent Assignment object for an AssignmentTeam' do
      assignment = Assignment.create!(title: 'Parent Assignment', instructor: instructor)
      result = AssignmentTeam.find_parent_entity(assignment.id)
      expect(result).to eq(assignment)
    end
  end

  describe '#participants' do
    it 'returns participants for each user in the team' do
      team = Team.create!(name: 'PartTeam', parent_id: user_parent.id, assignment: assignment)

      user1 = User.create!(
        name: 'userA', full_name: 'User A', email: 'usera@example.com',
        password: 'password', role: role, parent: user_parent
      )
      user2 = User.create!(
        name: 'userB', full_name: 'User B', email: 'userb@example.com',
        password: 'password', role: role, parent: user_parent
      )

      participant1 = AssignmentParticipant.create!(user: user1, assignment: assignment, handle: 'handle1')
      participant2 = AssignmentParticipant.create!(user: user2, assignment: assignment, handle: 'handle2')

      TeamsParticipant.create!(participant: participant1, team: team)
      TeamsParticipant.create!(participant: participant2, team: team)

      expect(team.participants.map(&:id)).to contain_exactly(participant1.id, participant2.id)
    end
  end

  describe '#copy_content' do
    it 'calls copy on each element with destination id' do
      source = [double('Element1'), double('Element2')]
      destination = double('Destination', id: 42)

      source.each do |el|
        expect(el).to receive(:copy).with(42)
      end

      Team.copy_content(source, destination)
    end
  end

  describe '#delete' do
    it 'deletes the team and its team node without touching bids' do
      team = Team.create!(name: 'TeamToDelete', parent_id: assignment.id, assignment: assignment)
      # build a participant for the instructor and join via TeamsParticipant
      participant = AssignmentParticipant.create!(
        user: instructor,
        assignment: assignment,
        handle: 'instructor_handle'
      )
      TeamsParticipant.create!(team: team, participant: participant)

      allow(team).to receive(:destroy).and_return(true)

      mock_node = double('TeamNode', destroy: true)
      allow(TeamNode).to receive(:find_by).with(node_object_id: team.id).and_return(mock_node)

      expect(team).to receive(:destroy)
      team.delete
    end
  end

  describe '#node_type' do
    it 'returns "TeamNode"' do
      team = Team.new
      expect(team.node_type).to eq('TeamNode')
    end
  end

  describe '#member_names' do
    it 'returns full names of associated users' do
      team = Team.create!(name: 'TeamTest', parent_id: assignment.id, assignment: assignment)

      user1 = User.create!(
        name: 'user1', full_name: 'Full Name 1', email: 'user1@example.com',
        password: 'password', role: role
      )
      user2 = User.create!(
        name: 'user2', full_name: 'Full Name 2', email: 'user2@example.com',
        password: 'password', role: role
      )

      participant1 = AssignmentParticipant.create!(user: user1, assignment: assignment, handle: 'handle1')
      participant2 = AssignmentParticipant.create!(user: user2, assignment: assignment, handle: 'handle2')

      TeamsParticipant.create!(participant: participant1, team: team)
      TeamsParticipant.create!(participant: participant2, team: team)

      expect(team.member_names).to contain_exactly('Full Name 1', 'Full Name 2')
    end
  end

  describe '#has_as_member?' do
    it 'returns true if user is a member' do
      team = Team.create!(name: 'TeamTest', parent_id: assignment.id, assignment: assignment)
      user = User.create!(
        name: 'user3', full_name: 'Full Name', email: 'user3@example.com',
        password: 'password', role: role
      )
      participant = AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'handle')
      TeamsParticipant.create!(team: team, participant: participant)

      expect(team.has_as_member?(user)).to be true
    end

    it 'returns false if user is not a member' do
      team = Team.create!(name: 'TeamTest', parent_id: assignment.id, assignment: assignment)
      user = User.create!(
        name: 'user4', full_name: 'Full Name', email: 'user4@example.com',
        password: 'password', role: role
      )
      AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'handle')

      expect(team.has_as_member?(user)).to be false
    end
  end

  describe '#full?' do
    it 'returns false for course team (no max size limit)' do
      team = Team.create!(name: 'TeamTest', parent_id: nil, assignment: assignment)
      expect(team.full?).to be false
    end

    it 'returns false if team size is below max' do
      assignment.update!(max_team_size: 2)
      team = Team.create!(name: 'TeamTest', parent_id: assignment.id, assignment: assignment)
      user = User.create!(
        name: 'user7', full_name: 'Full Name', email: 'user7@example.com',
        password: 'password', role: role
      )
      participant = AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'h7')
      TeamsParticipant.create!(team: team, participant: participant)

      expect(team.full?).to be false
    end

    it 'returns true if team size equals or exceeds max' do
      assignment.update!(max_team_size: 1)
      team = Team.create!(name: 'TeamTest', parent_id: assignment.id, assignment: assignment)
      user = User.create!(
        name: 'user8', full_name: 'Full Name', email: 'user8@example.com',
        password: 'password', role: role
      )
      participant = AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'h8')
      TeamsParticipant.create!(team: team, participant: participant)

      expect(team.full?).to be true
    end
  end

  describe '#add_member' do
    let(:team) { AssignmentTeam.create!(name: 'TeamAdd', parent_id: assignment.id, assignment_id: assignment.id) }
    let(:user) { User.create!(name: 'new_user', full_name: 'New Member', email: 'new@example.com', password: 'password', role: role) }

    before do
      AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'new_handle')
      allow(TeamNode).to receive(:find_by).and_return(double('TeamNode', id: 1))
      allow(TeamUserNode).to receive(:create)
      allow(CourseParticipant).to receive(:find_by).and_return(nil)
      allow(CourseParticipant).to receive(:create)
    end

    it 'adds a user to the team successfully' do
      assignment.update!(max_team_size: 5)
      result = team.add_member(user)
      expect(result).to be true
    end

    it 'raises an error if the user is already a member' do
      assignment.update!(max_team_size: 5) # ✅ Ensure it's not nil

      TeamsParticipant.create!(
        team: team,
        participant: AssignmentParticipant.find_by(user: user, assignment: assignment)
      )

      expect { team.add_member(user) }.to raise_error(RuntimeError, /already a member/)
    end

    it 'returns false if the team is full' do
      assignment.update!(max_team_size: 0)
      expect(team.add_member(user)).to be false
    end
  end

  describe '#import_team_members' do
    let(:team) { AssignmentTeam.create!(name: 'TeamImportMembers', parent_id: assignment.id, assignment_id: assignment.id) }

    it 'calls add_member for each listed user' do
      u1 = User.create!(name: 'one', full_name: 'One', email: 'one@e.com', password: 'password', role: role)
      u2 = User.create!(name: 'two', full_name: 'Two', email: 'two@e.com', password: 'password', role: role)

      expect(team).to receive(:add_member).with(u1)
      expect(team).to receive(:add_member).with(u2)

      row_hash = { teammembers: ['one', 'two'] }
      team.import_team_members(row_hash)
    end
  end

  describe '#import' do
    let(:klass)        { AssignmentTeam }
    let(:assignment_id){ assignment.id }

    it 'imports team and members' do
      u = User.create!(name: 'import', full_name: 'I', email: 'imp@e.com', password: 'password', role: role)
      AssignmentParticipant.create!(user: u, assignment_id: assignment.id, handle: 'import_handle')
      assignment.update!(max_team_size: 5)

      row     = { teamname: 'Import Team', teammembers: ['import'] }
      options = { has_teamname: 'true_first', handle_dups: 'insert' }
      fake    = AssignmentTeam.create!(name: 'Import Team', parent_id: assignment.id, assignment_id: assignment.id)

      allow(klass).to receive(:create_team_and_node).and_return(fake)
      allow(TeamNode).to receive(:find_by).and_return(double('TeamNode', id: 1))
      allow(TeamUserNode).to receive(:create)
      allow(CourseParticipant).to receive(:find_by).and_return(nil)
      allow(CourseParticipant).to receive(:create)

      expect { Team.import(row, assignment_id, options, klass) }.not_to raise_error
      expect(fake.participants.map(&:user)).to include(u)
    end
  end

  describe '#handle_duplicate' do
    let(:existing_team) { Team.create!(name: 'Existing', parent_id: assignment.id, assignment: assignment) }

    it 'returns name if none' do
      expect(Team.handle_duplicate(nil, 'Alpha', assignment.id, 'ignore', AssignmentTeam)).to eq('Alpha')
    end

    it 'returns nil on ignore' do
      expect(Team.handle_duplicate(existing_team, 'Existing', assignment.id, 'ignore', AssignmentTeam)).to be_nil
    end

    it 'renames on rename' do
      allow(Team).to receive(:generate_team_name).and_return('Renamed')
      expect(Team.handle_duplicate(existing_team, 'Existing', assignment.id, 'rename', AssignmentTeam)).to eq('Renamed')
    end

    it 'replaces on replace' do
      expect(existing_team).to receive(:delete)
      expect(Team.handle_duplicate(existing_team, 'Existing', assignment.id, 'replace', AssignmentTeam)).to eq('Existing')
    end

    it 'returns nil on insert' do
      expect(Team.handle_duplicate(existing_team, 'Existing', assignment.id, 'insert', AssignmentTeam)).to be_nil
    end
  end

  describe '#export' do
    it 'writes to CSV' do
      team = AssignmentTeam.create!(name: 'ExportTeam', parent_id: assignment.id, assignment_id: assignment.id)
      u    = User.create!(name: 'ex', full_name: 'Ex', email: 'ex@e.com', password: 'password', role: role)
      participant = AssignmentParticipant.create!(user: u, assignment_id: assignment.id, handle: 'ex_handle')
      TeamsParticipant.create!(participant: participant, team: team)

      csv     = []
      options = { team_name: 'false' }
      Team.export(csv, assignment.id, options, AssignmentTeam)

      expect(csv[0]).to include('ExportTeam', 'ex')
    end
  end

  describe '#create_team_and_node' do
    it 'builds team & node' do
      u1 = User.create!(name: 'n1', full_name: 'N1', email: 'n1@e.com', password: 'password', role: role)
      u2 = User.create!(name: 'n2', full_name: 'N2', email: 'n2@e.com', password: 'password', role: role)

      p1 = AssignmentParticipant.create!(user: u1, assignment_id: assignment.id, handle: 'h1')
      p2 = AssignmentParticipant.create!(user: u2, assignment_id: assignment.id, handle: 'h2')

      # Fake team to satisfy TeamsParticipant.where(participant_id: ...).find { ...team.parent_id... }
      dummy_team = AssignmentTeam.create!(name: 'dummy', parent_id: assignment.id, assignment_id: assignment.id)
      TeamsParticipant.create!(participant: p1, team: dummy_team)
      TeamsParticipant.create!(participant: p2, team: dummy_team)

      allow(Team).to receive(:find_parent_entity).with(assignment.id).and_return(assignment)
      allow(TeamNode).to receive(:create)
      allow_any_instance_of(Team).to receive(:add_member).and_return(true)

      team = Team.create_team_and_node(assignment.id, [u1.id, u2.id])

      expect(team).to be_a(Team)
      expect(team.parent_id).to eq(assignment.id)
      expect(team.name).to match(/Team_\d+/)
    end
  end

  describe '#find_team_for_user' do
    it 'finds team by user' do
      u = User.create!(name: 'tu', full_name: 'TU', email: 'tu@e.com', password: 'password', role: role)
      team = AssignmentTeam.create!(name: 'FT', parent_id: assignment.id, assignment_id: assignment.id)
      participant = AssignmentParticipant.create!(user: u, assignment_id: assignment.id, handle: 'tu_handle')
      TeamsParticipant.create!(participant: participant, team: team)

      res = Team.find_team_for_user(assignment.id, u.id)
      expect(res.first.t_id).to eq(team.id)
    end
  end

  describe '#has_participant?' do
    it 'true if in' do
      team = Team.create!(name: 'PT', parent_id: assignment.id, assignment: assignment)
      pnt  = AssignmentParticipant.create!(user: instructor, assignment_id: assignment.id, handle: 'h')
      allow(team).to receive(:participants).and_return([pnt])
      expect(team.has_participant?(pnt)).to be true
    end

    it 'false if not' do
      team = Team.create!(name: 'NPT', parent_id: assignment.id, assignment: assignment)
      pnt  = AssignmentParticipant.create!(user: instructor, assignment_id: assignment.id, handle: 'h2')
      allow(team).to receive(:participants).and_return([])
      expect(team.has_participant?(pnt)).to be false
    end
  end
end
