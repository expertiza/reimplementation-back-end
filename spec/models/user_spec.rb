require 'rails_helper'

RSpec.describe User, type: :model do

  # describe ".find_by_login" do
  #   context "when login is an email" do
  #     it "returns the user with the matching email" do
  #       # Test scenario 1
  #       # Given an existing user with email "test@example.com"
  #       # When calling .find_by_login("test@example.com")
  #       # Then it should return the user with email "test@example.com"
  #
  #       # Test scenario 2
  #       # Given no user with email "test@example.com" exists
  #       # When calling .find_by_login("test@example.com")
  #       # Then it should return nil
  #     end
  #   end
  #
  #   context "when login is not an email" do
  #     it "returns the user with the matching name" do
  #       # Test scenario 3
  #       # Given an existing user with name "john_doe"
  #       # When calling .find_by_login("john_doe@example.com")
  #       # Then it should return the user with name "john_doe"
  #
  #       # Test scenario 4
  #       # Given multiple users with name "john_doe" exist
  #       # When calling .find_by_login("john_doe@example.com")
  #       # Then it should return the first user with name "john_doe"
  #
  #       # Test scenario 5
  #       # Given no user with name "john_doe" exists
  #       # When calling .find_by_login("john_doe@example.com")
  #       # Then it should return nil
  #     end
  #   end
  # end


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
