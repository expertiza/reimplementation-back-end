# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  
  let(:role) { create(:role, :student) }
  let(:institution) { create(:institution) }

  let(:user) { create(:user, role: role, institution: institution) }

  describe 'validations' do
    it 'validates presence of name' do
      user.name = nil
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      duplicate_user = user.dup
      duplicate_user.name = user.name
      duplicate_user.save
      expect(duplicate_user.errors[:name]).to include('has already been taken')
    end

    it 'validates presence of email' do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'validates email format' do
      user.email = 'invalid_email'
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'validates password length' do
      user.password = 'short'
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end

    it 'validates presence of full_name' do
      user.full_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it { should belong_to(:role) }
    it { should belong_to(:institution).optional }
    it { should belong_to(:parent).class_name('User').optional }
    it { should have_many(:users).dependent(:nullify) }
    it { should have_many(:invitations) }
    it { should have_many(:assignments) }
    it { should have_many(:teams_users).dependent(:destroy) }
    it { should have_many(:teams).through(:teams_users) }
    it { should have_many(:participants) }
  end

  describe 'callbacks' do
    it 'sets default values on initialization' do
      new_user = User.new
      expect(new_user.is_new_user).to be true
      expect(new_user.copy_of_emails).to be false
      expect(new_user.email_on_review).to be false
      expect(new_user.email_on_submission).to be false
      expect(new_user.email_on_review_of_review).to be false
      expect(new_user.etc_icons_on_homepage).to be true
    end
  end

  describe '#login_user' do
    it 'returns a user when login is email' do
      result = User.login_user(user.email)
      expect(result).to eq(user)
    end

    it 'returns a user when login is name' do
      result = User.login_user(user.name)
      expect(result).to eq(user)
    end

    it 'returns nil if no user is found' do
      result = User.login_user('nonexistent_user')
      expect(result).to be_nil
    end
  end

  describe '#reset_password' do
    it 'resets the password and saves the user' do
      old_password_digest = user.password_digest
      user.reset_password
      expect(user.password_digest).not_to eq(old_password_digest)
      expect(user.save).to be_truthy
    end
  end

  describe '#instructor_id' do
    it 'returns the user id if the user is an instructor' do
      user.update(role: create(:role, :instructor))
      expect(user.instructor_id).to eq(user.id)
    end

    it 'returns the instructor id if the user is a teaching assistant' do
      ta_user = create(:user, role: create(:role, :ta))
      instructor = create(:user, role: create(:role, :instructor))
      ta_user.update(parent: instructor)
      expect(ta_user.instructor_id).to eq(instructor.id)
    end
  end

  describe '#generate_password_reset_token!' do
    it 'generates and saves a reset password token' do
      expect(user.reset_password_token).to be_nil
      user.generate_password_reset_token!
      expect(user.reset_password_token).not_to be_nil
      expect(user.reset_password_sent_at).not_to be_nil
    end
  end

  describe '#clear_password_reset_token!' do
    it 'clears the reset password token' do
      user.generate_password_reset_token!
      token = user.reset_password_token
      user.clear_password_reset_token!
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil
    end
  end

  describe '#password_reset_valid?' do
    it 'returns true if the reset password token is valid (within 24 hours)' do
      user.generate_password_reset_token!
      user.reset_password_sent_at = Time.zone.now - 1.hour
      expect(user.password_reset_valid?).to be true
    end

    it 'returns false if the reset password token is expired (older than 24 hours)' do
      user.generate_password_reset_token!
      user.reset_password_sent_at = Time.zone.now - 25.hours
      expect(user.password_reset_valid?).to be false
    end
  end
end
