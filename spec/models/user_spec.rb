require 'rails_helper'

RSpec.describe User, type: :model do

  describe '.find_by_userid' do
    context 'when userid is an email' do
      let!(:user) { create(:user, name: 'testname', email: 'test@test.com') }
      it 'returns the user with the matching email' do
        result = User.find_by_userid('test@test.com')
        expect(result).to eq(user)
      end

      it 'returns nil when user with email doesnt exist' do
        result = User.find_by_login('test@unknown.com')
        expect(result).to eq(nil)
      end
    end

    context 'when userid is not an email' do
      let!(:user) { create(:user, name: 'testname', email: 'test@test.com') }
      let!(:user2) { build(:user, name: 'testname', email: 'test@test2.com') }
      it 'returns the user with the matching name' do
        result = User.find_by_userid('testname')
        expect(result).to eq(user)
      end
      it 'return first user with the matching name' do
        user2.save
        result = User.find_by_userid('testname')
        expect(result).to eq(user)
      end
      it 'return nil when no user with matching name' do
        result = User.find_by_userid('unknown')
        expect(result).to eq(nil)
      end
    end
  end


  describe '.search_users' do
    # Creating dummy objects for the test with the help of let statement
    let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
    let(:instructor) do
      Instructor.create(id: 1234, name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor',
                        password: '123456', role_id: 2)
    end

    context 'when searching by name' do
      it 'returns users with matching names' do
        # Test scenario 1
        search_result = User.search_users(nil, 'testins', 'name')
        expect(search_result).to include(instructor)

        # Test scenario 2
        search_result = User.search_users(nil, 'unknown', 'name')
        expect(search_result).to be_empty
      end
    end

    context 'when searching by fullname' do
      it 'returns users with matching fullnames' do
        # Test scenario 1
        search_result = User.search_users(nil, 'Test', 'full_name')
        expect(search_result).to include(instructor)

        # Test scenario 2
        search_result = User.search_users(nil, 'UnknownName', 'full_name')
        expect(search_result).to be_empty
      end
    end

    context 'when searching by email' do
      it 'returns users with matching emails' do
        # Test scenario 1
        search_result = User.search_users(nil, 'test@test.com', 'email')
        expect(search_result).to include(instructor)

        # Test scenario 2
        search_result = User.search_users(nil, 'unknown@test.com', 'email')
        expect(search_result).to be_empty
      end
    end

    context 'when searching by default' do
      it 'returns users with names starting with the specified id' do
        # Test scenario 1
        search_result = User.search_users(instructor.id, nil, nil)
        expect(search_result.map(&:id)).to include(instructor.id)

        # Test scenario 2
        search_result = User.search_users(9999, nil, nil) # Use an invalid user_id
        expect(search_result).to be_empty
      end
    end
    context 'when searching by role' do
      it 'returns users with matching roles' do
        # Test scenario 1
        search_result = User.search_users(nil, 'admin', 'role')
        expect(search_result.map(&:id)).to include(instructor.role_id)

        # Test scenario 2
        search_result = User.search_users(nil, 'unknown', 'role')
        expect(search_result).to be_empty
      end
    end
  end
end
