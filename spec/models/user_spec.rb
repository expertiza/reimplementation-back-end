require 'rails_helper'

RSpec.describe User, type: :model do

  describe '.find_by_login' do
    context 'when login is an email' do
      let!(:user) { create(:user, name: 'testname', email: 'test@test.com') }
      it 'returns the user with the matching email' do
        result = User.find_by_login('test@test.com')
        expect(result).to eq(user)
      end

      it 'returns nil when user with email doesnt exist' do
        result = User.find_by_login('test@unknown.com')
        expect(result).to eq(nil)
      end
    end

    context 'when login is not an email' do
      let!(:user) { create(:user, name: 'testname', email: 'test@test.com') }
      let!(:user2) { build(:user, name: 'testname', email: 'test@test2.com') }
      it 'returns the user with the matching name' do
        result = User.find_by_login('testname')
        expect(result).to eq(user)
      end
      it 'return first user with the matching name' do
        user2.save
        result = User.find_by_login('testname')
        expect(result).to eq(user)
      end
      it 'return nil when no user with matching name' do
        result = User.find_by_login('unknown')
        expect(result).to eq(nil)
      end
    end
  end

  # describe '.search_users' do
  #   context 'when searching by name' do
  #     it 'returns users with matching names' do
  #       # Test scenario 1
  #       # Description: When searching by name, it should return users whose names contain the specified letter.
  #       # Method call: search_users(role, user_id, letter, 1)
  #       # Expected result: Returns users with names containing the specified letter.
  #
  #       # Test scenario 2
  #       # Description: When searching by name, it should return an empty array if no users have names containing the specified letter.
  #       # Method call: search_users(role, user_id, letter, 1)
  #       # Expected result: Returns an empty array.
  #     end
  #   end

  describe '.search_users' do
    let(:super_admin_role) { Role.find_or_create_by(name: 'Super Administrator') }
    let(:user) { create(:user, role: super_admin_role) }

    context 'when the user is a Super Administrator' do
      it 'returns users with matching roles' do
        # Test scenario: When searching by role, it should return users with matching roles.
        result = User.search_users(user, 'Admin', 'role')
        expect(result).to include(user)
      end

      it 'returns an empty array if no users match the criteria' do
        # Test scenario: When no users match the specified criteria, it should return an empty array.
        result = User.search_users(user, 'Nonexistent', 'name')
        expect(result).to eq([])
      end
    end

    context 'when the user is not a Super Administrator' do
      let(:regular_user) { create(:user) }

      it 'returns unauthorized when the user is not a Super Administrator' do
        result = User.search_users(regular_user, 'paolajones', 'name')
        expect(result).to eq('Not Authorized')
      end
    end


  #
  #   context 'when searching by fullname' do
  #     it 'returns users with matching fullnames' do
  #       # Test scenario 1
  #       # Description: When searching by fullname, it should return users whose fullnames contain the specified letter.
  #       # Method call: search_users(role, user_id, letter, 2)
  #       # Expected result: Returns users with fullnames containing the specified letter.
  #
  #       # Test scenario 2
  #       # Description: When searching by fullname, it should return an empty array if no users have fullnames containing the specified letter.
  #       # Method call: search_users(role, user_id, letter, 2)
  #       # Expected result: Returns an empty array.
  #     end
  #   end
  #
  #   context 'when searching by email' do
  #     it 'returns users with matching emails' do
  #       # Test scenario 1
  #       # Description: When searching by email, it should return users whose emails contain the specified letter.
  #       # Method call: search_users(role, user_id, letter, 3)
  #       # Expected result: Returns users with emails containing the specified letter.
  #
  #       # Test scenario 2
  #       # Description: When searching by email, it should return an empty array if no users have emails containing the specified letter.
  #       # Method call: search_users(role, user_id, letter, 3)
  #       # Expected result: Returns an empty array.
  #     end
  #   end
  #
  #   context 'when searching by default' do
  #     it 'returns users with names starting with the specified letter' do
  #       # Test scenario 1
  #       # Description: When searching by default, it should return users whose names start with the specified letter.
  #       # Method call: search_users(role, user_id, letter, 4)
  #       # Expected result: Returns users with names starting with the specified letter.
  #
  #       # Test scenario 2
  #       # Description: When searching by default, it should return an empty array if no users have names starting with the specified letter.
  #       # Method call: search_users(role, user_id, letter, 4)
  #       # Expected result: Returns an empty array.
  #     end
  #   end
   end

end
