require 'rails_helper'

describe Course, type: :model do
  let(:role) {Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil)}
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:institution) { create(:institution, id: 1) }
  let(:course) { create(:course, id: 1, name: 'ECE517', instructor: instructor, institution: institution) }
  let(:user1) { create(:user, name: 'abcdef', full_name:'abc bbc', email: 'abcbbc@gmail.com', password: '123456789', password_confirmation: '123456789', role: role) }

  describe 'validations' do
    it 'validates presence of name' do
      course.name = ''
      expect(course).not_to be_valid
    end
    it 'validates presence of directory_path' do
      course.directory_path = ' '
      expect(course).not_to be_valid
    end
  end



  describe '#path' do
    context 'when there is no associated instructor' do
      it 'an error is raised' do
        allow(course).to receive(:instructor_id).and_return(nil)
        expect { course.path }.to raise_error('Path can not be created as the course must be associated with an instructor.')
      end
    end
    context 'when there is an associated instructor' do
      it 'returns a directory' do
        allow(course).to receive(:instructor_id).and_return(6)
        allow(User).to receive(:find).with(6).and_return(user1)
        allow(course).to receive(:institution_id).and_return(1)
        allow(Institution).to receive(:find).with(1).and_return(institution)
        expect(course.path.directory?).to be_truthy
      end
    end
  end

end
