require 'rails_helper'

RSpec.describe Participant, type: :model do
  # Use a dummy instructor for assignment creation.
  let(:dummy_instructor) do
    # If the instructor trait isn’t available, simply create a user with a role that qualifies.
    instructor_role = create(:role, :instructor) rescue create(:role)
    instructor_institution = create(:institution)
    create(:user, role: instructor_role, institution: instructor_institution)
  end

  # Override assignment to use our dummy instructor.
  let(:assignment) { create(:assignment, instructor: dummy_instructor) }

  describe "associations" do
    it "belongs to a user" do
      role = create(:role, :student)
      institution = create(:institution)
      user = create(:user, role: role, institution: institution)
      participant = Participant.new(user: user, assignment: assignment)
      expect(participant.user).to eq(user)
    end

    it "belongs to an assignment" do
      role = create(:role, :student)
      institution = create(:institution)
      user = create(:user, role: role, institution: institution)
      participant = Participant.new(user: user, assignment: assignment)
      expect(participant.assignment).to eq(assignment)
    end

    it "can optionally belong to a team" do
      role = create(:role, :student)
      institution = create(:institution)
      user = create(:user, role: role, institution: institution)
      # Instead of using create(:team) which fails due to a missing name attribute,
      # instantiate a team manually.
      team = Team.new(assignment: assignment)
      participant = Participant.new(user: user, assignment: assignment, team: team)
      expect(participant.team).to eq(team)
    end

    it 'has many join_team_requests with dependent: :destroy' do
      assoc = Participant.reflect_on_association(:join_team_requests)
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is invalid without a user" do
      participant = Participant.new(user: nil, assignment: assignment)
      expect(participant).not_to be_valid
      expect(participant.errors[:user]).to include("must exist")
    end
  end

  describe "custom validations" do
    it "is invalid without assignment and course" do
      role = create(:role, :student)
      institution = create(:institution)
      user = create(:user, role: role, institution: institution)

      participant = Participant.new(user: user, assignment: nil, course_id: nil)

      expect(participant).not_to be_valid
      expect(participant.errors[:base]).to include("Either assignment or course must be present")
    end

    it "is valid with assignment present" do
      # Manually create the instructor role (using the trait with explicit ID)
      instructor_role = create(:role, :instructor)

      # Create a user with that role
      institution = create(:institution)
      instructor = create(:user, role: instructor_role, institution: institution)

      # Create an assignment with the instructor
      assignment = create(:assignment, instructor: instructor)

      # Create a participant with the assignment (no course)
      role = create(:role, :student)
      user = create(:user, role: role, institution: institution)
      participant = Participant.new(user: user, assignment: assignment)

      expect(participant).to be_valid
    end

    it "is valid with course_id present and no assignment" do
      student_role = create(:role, :student)
      instructor_role = create(:role, :instructor)
      institution = create(:institution)

      user = create(:user, role: student_role, institution: institution)
      instructor = create(:user, role: instructor_role, institution: institution)

      course = create(:course, instructor: instructor)  # explicitly assign correct type

      participant = Participant.new(user: user, assignment: nil, course_id: course.id)

      expect(participant).to be_valid
    end


  end


  describe "#fullname" do
    it "returns the full name of the associated user" do
      role = create(:role, :student)
      institution = create(:institution)
      user = create(:user, role: role, institution: institution, full_name: "Jane Doe")

      # Dynamically add a fullname method to this user instance.
      user.define_singleton_method(:fullname) { full_name }

      participant = Participant.new(user: user, assignment: assignment)
      expect(participant.name).to eq("Jane Doe")
    end
  end

  describe "#responses" do
    let(:student_role) { create(:role, :student) }
    let(:institution)  { create(:institution) }
    let(:user)         { create(:user, role: student_role, institution: institution) }
    let(:participant)  { create(:participant, user: user, assignment: assignment) }

    context "when there are no response_maps" do
      it "returns an empty array" do
        expect(participant.responses).to eq([])
      end
    end

    context "when there are response_maps" do
      let(:resp1) { double("resp1") }
      let(:resp2) { double("resp2") }

      let(:rm1) { instance_double(ResponseMap, response: resp1) }
      let(:rm2) { instance_double(ResponseMap, response: resp2) }

      let(:maps) do
        arr = [rm1, rm2]
        # define a real `includes` on this single object
        def arr.includes(*_args)
          self
        end
        arr
      end

      before do
        allow(participant).to receive(:response_maps).and_return(maps)
      end

      it "returns all of the associated Response objects" do
        expect(participant.responses).to contain_exactly(resp1, resp2)
      end
    end
  end

  describe "#username" do
    let(:role)        { create(:role, :student) }
    let(:institution) { create(:institution) }
    let(:user)        { create(:user, role: role, institution: institution) }
    let(:participant) { Participant.new(user: user, assignment: assignment) }

    before do
      allow(user).to receive(:name).and_return("Alice")
    end

    it "returns the user's name" do
      expect(participant.username).to eq("Alice")
    end
  end

  describe "#delete" do
    let(:participant) { Participant.new(id: 42) }

    before do
      # never hit the real DB
      allow(participant).to receive(:destroy)
    end

    context "when there are response maps" do
      let(:fake_maps) { [double("RM1"), double("RM2")] }

      before do
        allow(ResponseMap).to receive(:where)
                                .with('reviewee_id = ? or reviewer_id = ?', participant.id, participant.id)
                                .and_return(fake_maps)
        allow(participant).to receive(:team).and_return(nil)
      end

      it "raises if not forced" do
        expect { participant.delete }.to \
          raise_error("Associations exist for this participant.")
      end

      it "destroys each map and then the participant when forced" do
        fake_maps.each { |m| expect(m).to receive(:destroy) }
        expect(participant).to receive(:destroy)

        participant.delete(true)
      end
    end

    context "when there is a team but no maps" do
      let(:fake_team_user) { double("TU", user_id: 42, destroy: true) }
      let(:fake_team)      { double("Team", teams_users: fake_team_users) }

      before do
        allow(ResponseMap).to receive(:where)
                                .and_return([])
        allow(participant).to receive(:team).and_return(fake_team)
      end

      context "and the team has exactly one member" do
        let(:fake_team_users) { [fake_team_user] }

        before do
          allow(fake_team).to receive(:delete)
        end

        it "raises if not forced" do
          expect { participant.delete }.to \
            raise_error("Associations exist for this participant.")
        end

        it "calls team.delete and then destroys the participant when forced" do
          expect(fake_team).to receive(:delete)
          expect(participant).to receive(:destroy)

          participant.delete(true)
        end
      end

      context "and the team has more than one member" do
        let(:other_tu)       { double("OtherTU", user_id: 99, destroy: true) }
        let(:fake_team_users) { [fake_team_user, other_tu] }

        it "removes only the TU for this participant and then destroys the participant" do
          expect(fake_team_user).to receive(:destroy)
          expect(other_tu).not_to receive(:destroy)
          expect(participant).to receive(:destroy)

          participant.delete(true)
        end
      end
    end

    context "when there are no maps and no team" do
      before do
        allow(ResponseMap).to receive(:where).and_return([])
        allow(participant).to receive(:team).and_return(nil)
      end

      it "just destroys the participant" do
        expect(participant).to receive(:destroy)
        participant.delete
      end
    end
  end

  describe "#authorization" do
    let(:student_role) { create(:role, :student) }
    let(:instructor_role) { create(:role, :instructor) }
    let(:institution) { create(:institution) }
    let(:user) { create(:user, role: student_role, institution: institution) }
    let(:assignment) { create(:assignment, instructor: create(:user, role: instructor_role, institution: institution)) }

    subject(:participant) do
      build(
        :participant,
        user: user,
        assignment: assignment,
        can_submit: can_submit,
        can_review: can_review,
        can_take_quiz: can_take_quiz,
        can_mentor: can_mentor
      )
    end

    context "when no special permissions are granted" do
      let(:can_submit)    { false }
      let(:can_review)    { false }
      let(:can_take_quiz) { false }
      let(:can_mentor)    { false }

      it "returns 'participant'" do
        expect(participant.task_role).to eq("participant")
      end
    end

    context "when the participant is marked as a mentor" do
      let(:can_submit)    { false }
      let(:can_review)    { false }
      let(:can_take_quiz) { false }
      let(:can_mentor)    { true }

      it "returns 'mentor'" do
        expect(participant.task_role).to eq("mentor")
      end
    end

    context "when eligible only for reading" do
      let(:can_submit)    { false }
      let(:can_review)    { true }
      let(:can_take_quiz) { true }
      let(:can_mentor)    { false }

      it "returns 'reader'" do
        expect(participant.task_role).to eq("reader")
      end
    end

    context "when eligible only to submit" do
      let(:can_submit)    { true }
      let(:can_review)    { false }
      let(:can_take_quiz) { false }
      let(:can_mentor)    { false }

      it "returns 'submitter'" do
        expect(participant.task_role).to eq("submitter")
      end
    end

    context "when eligible only to review" do
      let(:can_submit)    { false }
      let(:can_review)    { true }
      let(:can_take_quiz) { false }
      let(:can_mentor)    { false }

      it "returns 'reviewer'" do
        expect(participant.task_role).to eq("reviewer")
      end
    end
  end

  describe ".export" do
    let(:instructor) { create(:user, role: create(:role, :instructor), institution: create(:institution)) }
    let(:assignment) { create(:assignment, instructor: instructor) }
    let(:student)    { create(:user, role: create(:role, :student), institution: create(:institution)) }
    let!(:part1)     { create(:participant, user: student, assignment: assignment, handle: "h1") }
    let!(:part2)     { create(:participant, user: student, assignment: assignment, handle: "h2") }

    it "exports only the requested fields" do
      csv     = []
      options = {
        'personal_details' => 'true',
        'role'             => 'true',
        'parent'           => 'true',
        'email_options'    => 'true',
        'handle'           => 'true'
      }

      Participant.export(csv, assignment.id, options)

      expect(csv.size).to eq(2)
      csv.each do |row|
        expect(row).to include(
                         student.name,
                         student.full_name,
                         student.email,
                         student.role.name,
                         student.institution.name,
                         student.email_on_submission,
                         student.email_on_review,
                         student.email_on_review_of_review,
                         match(/^h[12]$/)
                       )
      end
    end

    it "omits fields when options are false" do
      csv = []
      opts = {
        'personal_details' => 'false',
        'role'             => 'false',
        'parent'           => 'false',
        'email_options'    => 'false',
        'handle'           => 'false'
      }

      Participant.export(csv, assignment.id, opts)
      expect(csv).to all(eq([]))
    end
  end

  describe '.export_fields' do
    let(:all_true_options) do
      {
        'personal_details' => 'true',
        'role' => 'true',
        'parent' => 'true',
        'email_options' => 'true',
        'handle' => 'true'
      }
    end

    it 'returns all fields when all options are set to true' do
      expected_fields = [
        'name', 'full name', 'email',
        'role',
        'parent',
        'email on submission', 'email on review', 'email on metareview',
        'handle'
      ]
      fields = described_class.export_fields(all_true_options)
      expect(fields).to match_array(expected_fields)
    end

    it 'returns only selected fields when some options are true' do
      selected_options = {
        'personal_details' => 'true',
        'email_options' => 'true'
      }
      expected_fields = [
        'name', 'full name', 'email',
        'email on submission', 'email on review', 'email on metareview'
      ]
      fields = described_class.export_fields(selected_options)
      expect(fields).to match_array(expected_fields)
    end

    it 'returns an empty array when all options are false' do
      options = {
        'personal_details' => 'false',
        'role' => 'false',
        'parent' => 'false',
        'email_options' => 'false',
        'handle' => 'false'
      }
      expect(described_class.export_fields(options)).to eq([])
    end
  end
end
