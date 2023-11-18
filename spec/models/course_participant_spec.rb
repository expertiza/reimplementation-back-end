require "rails_helper"

describe 'CourseParticipant' do
  describe '#copy' do
    before(:each) do
      @assignment = create(:assignment)
      @course_participant = build(:course_participant)
      @assignment_participant = build(:participant)
    end

    it 'creates a copy of the participant' do
      allow(AssignmentParticipant).to receive(:create).and_return(@assignment_participant)
      allow(@assignment_participant).to receive(:set_handle).and_return(true)

      result = @course_participant.copy(@assignment.id)

      expect(result).to be_an_instance_of(AssignmentParticipant)
    end

    it 'returns nil if copy exists' do
      # Stub AssignmentParticipant.find_or_create_by to return nil, simulating the case where a copy already exists
      allow(AssignmentParticipant).to receive(:find_or_create_by)
                                        .with(user_id: @course_participant.user.id, parent_id: @assignment.id)
                                        .and_return(nil)

      result = @course_participant.copy(@assignment.id)

      expect(result).to be_nil
    end

  end


  describe '#import' do
    it 'raise error if record is empty' do
      row = []
      expect { CourseParticipant.import(row, nil, nil, nil) }.to raise_error('No user id has been specified.')
    end

    it 'raise error if record does not have enough items ' do
      row = { username: 'user_name', full_name: 'user_fullname', email: 'name@email.com' }
      expect { CourseParticipant.import(row, nil, nil, nil) }.to raise_error("The record containing #{row[:name]} does not have enough items.")
    end


    it 'raises an error if the course with the given id is not found' do
      course_id = 2
      session = { user: build(:user, id: 1) }
      row = { username: 'username', full_name: 'user_fullname', email: 'name@gmail.com', password: 'user_password' }

      # Ensure the user exists or create it
      user = User.find_by(name: row[:username]) || create(:user, name: row[:username])

      allow(Course).to receive(:find).with(course_id).and_return(nil)

      expect { CourseParticipant.import(row, nil, session, course_id) }.to raise_error(ArgumentError, /The course with the id ['"]#{course_id}['"] was not found\./)
    end


    it 'creates course participant form record' do
      course = build(:course)
      session = {}
      allow(Course).to receive(:find).and_return(course)
      allow(session[:user]).to receive(:id).and_return(1)
      row = { username: 'username', full_name: 'user_fullname', email: 'name@email.com', role: 'user_role_name', parent: 'user_parent_name',password: 'user_password' }

      # Ensure the user exists or create it
      user = User.find_by(name: row[:username]) || create(:user, name: row[:username])

      course_part = CourseParticipant.import(row, nil, session, 2)
      expect(course_part).to be_an_instance_of(CourseParticipant)
    end

  end

  # describe '#export' do
  #   it 'checks if csv file is created' do
  #     options = { 'personal_details' => 'true' }
  #     course_participant = create(:course_participant)
  #     course_participant[:parent_id] = 2
  #     CSV.open('t.csv', 'ab') do |csv|
  #       CourseParticipant.export(csv, 2, options)
  #     end
  #   end
  # end

  describe '#export_fields' do
    it 'option is empty fields is empty' do
      fields = []
      options = {}
      expect(CourseParticipant.export_fields(options)).to be_empty
    end

    it 'option is not empty fields is not empty' do
      fields = []
      options = { 'personal_details' => 'true' }
      fields = CourseParticipant.export_fields(options)
      expect(fields).not_to be_empty
    end
  end


# describe "#path" do
  # context "when the parent course exists" do
  #   it "returns the path of the parent course concatenated with the directory number" do
  #     # Create a course with an id of 1 and a path of '/courses/1/'
  #     course = create(:course, id: 1, directory_path: '/courses/1/')
  #
  #     # Create a course participant with directory_num of 123 and parent_id of 1
  #     course_participant = create(:course_participant, directory_num: 123, parent_id: 1)
  #
  #     # Call the path method and expect the result to be '/courses/1/123/'
  #     expect(course_participant.path).to eq('/courses/1/123/')
  #   end
  # end
  #
  # context "when the parent course does not exist" do
  #   it "raises an error" do
  #     # Use build_stubbed instead of build to create a non-persisted instance
  #     course_participant = build_stubbed(:course_participant, parent_id: 2)
  #
  #     # Expect calling path to raise an ActiveRecord::RecordNotFound error
  #     expect { course_participant.path }.to raise_error(ActiveRecord::RecordNotFound)
  #   end
  # end
  # end
end