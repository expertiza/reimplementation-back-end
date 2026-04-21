# frozen_string_literal: true

require 'rails_helper'

describe Course, type: :model do
  before do
    allow_any_instance_of(User).to receive(:set_defaults)
  end

  let(:instructor) { create(:instructor) }
  let(:institution) { create(:institution) }
  let(:course) { create(:course, name: 'ECE517', instructor: instructor, institution: institution) }
  let(:user1) { create(:user, full_name: 'abc bbc', role: create(:role, :instructor)) }

  describe 'validations' do
    # Ensures the course requires a name to be valid.
    it 'validates presence of name' do
      course.name = ''
      expect(course).not_to be_valid
    end
    # Ensures the course requires a directory path to be valid.
    it 'validates presence of directory_path' do
      course.directory_path = ' '
      expect(course).not_to be_valid
    end
  end

  describe 'associations' do
    # Ensures users are reachable through course participants.
    it 'returns users through participants' do
      student = create(:user, :student)
      create(:course_participant, course: course, user: student)

      expect(course.users).to include(student)
    end
  end
  describe '#path' do
    context 'when there is no associated instructor' do
      # Raises an error if path is requested without an instructor.
      it 'an error is raised' do
        allow(course).to receive(:instructor_id).and_return(nil)
        expect { course.path }.to raise_error('Path can not be created as the course must be associated with an instructor.')
      end
    end
    context 'when there is an associated instructor' do
      # Returns a directory path when instructor and institution are present.
      it 'returns a directory' do
        allow(course).to receive(:instructor_id).and_return(6)
        allow(User).to receive(:find).with(6).and_return(user1)
        allow(course).to receive(:institution_id).and_return(1)
        allow(Institution).to receive(:find).with(1).and_return(institution)
        expect(course.path.directory?).to be_truthy
      end
    end
  end

  describe '#add_ta' do
    let(:ta_role) { create(:role, name: 'Teaching Assistant') }
    let(:ta_user) { create(:user, :ta) }

    # Adds a TA mapping and updates the user role to Teaching Assistant.
    it 'adds a TA and updates their role' do
      ta_role
      result = course.add_ta(ta_user)

      expect(result[:success]).to be(true)
      expect(result[:data]).to include('course_id' => course.id, 'user_id' => ta_user.id)
      expect(ta_user.reload.role.name).to eq('Teaching Assistant')
    end

    # Prevents adding a user who is already a TA for the course.
    it 'returns an error when the user is already a TA for the course' do
      TaMapping.create!(user_id: ta_user.id, course_id: course.id)
      result = course.add_ta(ta_user)

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq("The user with id #{ta_user.id} is already a TA for this course.")
    end

    # Returns a failure response when the user does not exist.
    it 'returns an error when the user is nil' do
      result = course.add_ta(nil)

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('The user with id  does not exist')
    end

    # Returns validation errors when the TA mapping cannot be saved.
    it 'returns mapping errors when save fails' do
      ta_role
      ta_mapping = instance_double(TaMapping, save: false, errors: 'invalid mapping')
      allow(TaMapping).to receive(:create).and_return(ta_mapping)

      result = course.add_ta(ta_user)

      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('invalid mapping')
    end
  end

  describe '#remove_ta' do
    let(:student_role) { create(:role, name: 'Student') }
    let(:ta_user) { create(:user, :ta) }

    # Returns an error when no TA mapping exists for the user.
    it 'returns an error when no mapping exists' do
      result = course.remove_ta(ta_user.id)
      expect(result[:success]).to be(false)
      expect(result[:message]).to eq('No TA mapping found for the specified course and TA')
    end

    # Removes the TA mapping and downgrades the role when it is the last assignment.
    it 'removes the mapping and downgrades role when it is the last mapping' do
      ta_mapping = TaMapping.create!(user_id: ta_user.id, course_id: course.id)
      allow(course.ta_mappings).to receive(:find_by).and_return(ta_mapping)
      allow(TaMapping).to receive(:where).with(user_id: ta_user.id).and_return([ta_mapping])
      stub_const('Role::STUDENT', student_role)

      result = course.remove_ta(ta_user.id)

      expect(result[:success]).to be(true)
      expect(result[:ta_name]).to eq(ta_user.name)
      expect(ta_user.reload.role).to eq(student_role)
    end
  end

  describe '#copy_course' do
    # Creates a duplicate course with updated name and directory path.
    it 'creates a copied course with updated name and directory_path' do
      result = course.copy_course

      expect(result).to be(true)
      copied_course = Course.find_by(name: "#{course.name}_copy")
      expect(copied_course).not_to be_nil
      expect(copied_course.directory_path).to eq("#{course.directory_path}_copy")
    end
  end

end
