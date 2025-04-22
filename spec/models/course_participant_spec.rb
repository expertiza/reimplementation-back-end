require 'rails_helper'

RSpec.describe CourseParticipant, type: :model do
  let(:student_role) { Role.create!(name: 'Student') }
  let(:user) do
    User.create!(
      name: 'stu',
      full_name: 'Student',
      email: 'stu@example.com',
      password: 'password',
      role: student_role
    )
  end
  let(:course) do
    Course.create!(
      name: 'TestCourse',
      directory_path: 'test_course',
      institution: Institution.create!(name: 'Inst'),
      instructor: user
    )
  end
  let(:assignment) do
    Assignment.create!(
      title: 'TestAssignment',
      directory_path: 'test_assign',
      instructor: user
    )
  end

  describe '#copy_to_assignment' do
    it 'creates a new AssignmentParticipant and sets its handle when none exists' do
      cp = CourseParticipant.create!(user: user, course: course, handle: 'orig')
      user.update!(handle: nil)

      part = cp.copy_to_assignment(assignment.id)

      expect(part).to be_a(AssignmentParticipant)
      expect(part.user_id).to eq(user.id)
      expect(part.assignment_id).to eq(assignment.id)
      expect(part.handle).to eq(user.name)
    end

    it 'returns existing participant if already present' do
      user.update!(handle: 'u_handle')
      existing = AssignmentParticipant.create!(user: user, assignment: assignment, handle: 'existing')
      cp = CourseParticipant.create!(user: user, course: course, handle: 'orig')

      part = cp.copy_to_assignment(assignment.id)
      expect(part.id).to eq(existing.id)
    end
  end

  describe '#set_handle' do
    it 'uses user.name when user.handle is blank' do
      user.update!(handle: nil)
      cp = CourseParticipant.new(user: user, course: course, handle: nil)
      cp.save!(validate: false)

      cp.set_handle
      expect(cp.handle).to eq(user.name)
    end

    it 'uses user.handle when present and unique' do
      user.update!(handle: 'unique_handle')
      cp = CourseParticipant.new(user: user, course: course, handle: nil)
      cp.save!(validate: false)

      cp.set_handle
      expect(cp.handle).to eq('unique_handle')
    end

    it 'falls back to user.name when handle is taken in same course' do
      user.update!(handle: 'dup')
      CourseParticipant.create!(user: user, course: course, handle: 'dup')
      cp2 = CourseParticipant.new(user: user, course: course, handle: nil)
      cp2.save!(validate: false)

      cp2.set_handle
      expect(cp2.handle).to eq(user.name)
    end
  end

  describe '.import' do
    let(:session) { {} }

    it 'raises ArgumentError if row_hash is empty' do
      expect {
        CourseParticipant.import({}, nil, session: session, course_id: course.id)
      }.to raise_error(ArgumentError, /No username provided/)
    end

    it 'raises ImportError if course not found' do
      expect {
        CourseParticipant.import({ username: user.name }, nil, session: session, course_id: 0)
      }.to raise_error(ImportError)
    end

    it 'creates a CourseParticipant for existing user and course' do
      expect {
        CourseParticipant.import({ username: user.name }, nil, session: session, course_id: course.id)
      }.to change { CourseParticipant.where(user_id: user.id, course_id: course.id).count }.by(1)
    end

    it 'does not create duplicate CourseParticipant' do
      CourseParticipant.create!(user: user, course: course, handle: 'orig')
      expect {
        CourseParticipant.import({ username: user.name }, nil, session: session, course_id: course.id)
      }.not_to change { CourseParticipant.where(user_id: user.id, course_id: course.id).count }
    end
  end

end
