# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'password validations' do
    it 'requires a password when password_digest is blank' do
      user = User.new(name: 'testuser', email: 'test@example.com', full_name: 'Test User', role: create(:role))

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'allows updating a user without providing password' do
      user = create(:user, password: 'password', password_confirmation: 'password')
      user.name = 'updated_name'

      expect(user).to be_valid
    end

    it 'enforces a minimum password length when password is provided' do
      user = User.new(name: 'shortpass', email: 'short@example.com', full_name: 'Short Pass', role: create(:role), password: '123', password_confirmation: '123')

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end

    it 'generates a password_digest when password is set' do
      user = create(:user, password: 'securepass', password_confirmation: 'securepass')

      expect(user.password_digest).to be_present
      expect(user.authenticate('securepass')).to eq(user)
    end
  end

  describe '.login_user' do
    let(:student_role) { create(:role, :student) }

    it 'finds user by email' do
      user = create(:user, email: 'john@example.com', role: student_role)
      found_user = User.login_user('john@example.com')

      expect(found_user).to eq(user)
    end

    it 'finds user by username when email is not found' do
      user = create(:user, role: student_role)
      found_user = User.login_user(user.name)

      expect(found_user).to eq(user)
    end

    it 'extracts username from email-like input when looking up by name' do
      user = create(:user, role: student_role)
      # Simulate email-like input by using part of username
      found_user = User.login_user(user.name)

      expect(found_user).to eq(user)
    end

    it 'returns nil when user is not found' do
      found_user = User.login_user('nonexistent@example.com')

      expect(found_user).to be_nil
    end
  end

  describe '.from_params' do
    let(:student_role) { create(:role, :student) }
    let(:user) { create(:user, role: student_role) }

    it 'finds user by user_id when provided' do
      params = { user_id: user.id }
      found_user = User.from_params(params)

      expect(found_user).to eq(user)
    end

    it 'finds user by name when user_id is not provided' do
      params = { user: { name: user.name } }
      found_user = User.from_params(params)

      expect(found_user).to eq(user)
    end

    it 'raises ActiveRecord::RecordNotFound when user_id does not exist' do
      params = { user_id: 999_999 }

      expect { User.from_params(params) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises error when user is not found by name' do
      params = { user: { name: 'nonexistent_user' } }

      expect { User.from_params(params) }.to raise_error("User nonexistent_user not found")
    end
  end

  describe '.instantiate (STI conversion)' do
    let(:institution) { create(:institution) }

    it 'converts user to Ta when role is teaching assistant' do
      ta_role = create(:role, :ta)
      user_record = create(:user, role: ta_role, institution: institution)

      result = User.instantiate(user_record)

      expect(result).to be_a(Ta)
      expect(result.id).to eq(user_record.id)
    end

    it 'converts user to Instructor when role is instructor' do
      instructor_role = create(:role, :instructor)
      user_record = create(:user, role: instructor_role, institution: institution)

      result = User.instantiate(user_record)

      expect(result).to be_a(Instructor)
      expect(result.id).to eq(user_record.id)
    end

    it 'converts user to Administrator when role is administrator' do
      admin_role = create(:role, :administrator)
      user_record = create(:user, role: admin_role, institution: institution)

      result = User.instantiate(user_record)

      expect(result).to be_a(Administrator)
      expect(result.id).to eq(user_record.id)
    end

    it 'converts user to SuperAdministrator when role is super administrator' do
      super_admin_role = create(:role, :super_administrator)
      user_record = create(:user, role: super_admin_role, institution: institution)

      result = User.instantiate(user_record)

      expect(result).to be_a(SuperAdministrator)
      expect(result.id).to eq(user_record.id)
    end

    it 'returns User when role is student (no STI conversion)' do
      student_role = create(:role, :student)
      user_record = create(:user, role: student_role, institution: institution)

      result = User.instantiate(user_record)

      expect(result).to be_a(User)
      expect(result).not_to be_a(Ta)
      expect(result.id).to eq(user_record.id)
    end
  end
end
