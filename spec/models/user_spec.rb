require 'rails_helper'

RSpec.describe User, type: :model do
  let(:role) { Role.find_or_create_by!(name: 'Student') }
  before do
    $redis = double('Redis', get: '')
  end

  describe '#login_user' do
    let!(:user) { User.create!(name: 'alex', full_name: 'Alex D', email: 'alex@email.com', password: 'password', role: role) }

    it 'finds user by email' do
      expect(User.login_user('alex@email.com')).to eq(user)
    end

    it 'finds user by name if email not found' do
      expect(User.login_user('alex@email.comX')).to eq(user)
    end
  end

  describe '#anonymized_view?' do
    it 'returns true if IP is in anonymized list' do
      allow($redis).to receive(:get).with('anonymized_view_starter_ips').and_return('1.2.3.4')
      expect(User.anonymized_view?('1.2.3.4')).to be true
    end
  
    it 'returns false if IP is not in anonymized list' do
      allow($redis).to receive(:get).with('anonymized_view_starter_ips').and_return('5.6.7.8')
      expect(User.anonymized_view?('1.2.3.4')).to be false
    end
  
    it 'returns false if no IP provided' do
      allow($redis).to receive(:get).with('anonymized_view_starter_ips').and_return('1.2.3.4')
      expect(User.anonymized_view?).to be false
    end
  end

  describe '#reset_password' do
    let!(:user) { User.create!(name: 'bob', full_name: 'Bobby', email: 'bob@example.com', password: 'password', role: role) }

    it 'changes the password digest' do
      old_digest = user.password_digest
      user.reset_password
      expect(user.password_digest).not_to eq(old_digest)
    end
  end

  describe '#instructor_id' do
    before do
      stub_const('Role::INSTRUCTOR', Role.find_or_create_by!(name: 'Instructor'))
      stub_const('Role::ADMINISTRATOR', Role.find_or_create_by!(name: 'Administrator'))
      stub_const('Role::SUPER_ADMINISTRATOR', Role.find_or_create_by!(name: 'Super Administrator'))
      stub_const('Role::TEACHING_ASSISTANT', Role.find_or_create_by!(name: 'Teaching Assistant'))
    end

    it 'returns own id if user is instructor/admin/superadmin' do
      roles = [Role::INSTRUCTOR, Role::ADMINISTRATOR, Role::SUPER_ADMINISTRATOR]
      roles.each_with_index do |role, i|
        user = User.create!(
          name: "user#{i}",
          full_name: 'Role User',
          email: "user#{i}@test.com",
          password: 'password',
          role: role
        )
        expect(user.instructor_id).to eq(user.id)
      end
    end

    it 'returns parent instructor id if user is a TA' do
      instructor = User.create!(
        name: 'real_instructor',
        full_name: 'Dr. Real',
        email: 'real_instructor@test.com',
        password: 'password',
        role: Role::INSTRUCTOR
      )

      ta = User.create!(
        name: 'ta_user',
        full_name: 'TA Helper',
        email: 'ta_user@test.com',
        password: 'password',
        role: Role::TEACHING_ASSISTANT,
        parent: instructor
      )

      def ta.my_instructor; parent.id; end

      expect(ta.instructor_id).to eq(instructor.id)
    end
  end

  describe '#from_params' do
    let!(:user) { User.create!(name: 'usman', full_name: 'Usman Khan', email: 'usman@email.com', password: 'password', role: role) }

    it 'retrieves user by user_id param' do
      expect(User.from_params({ user_id: user.id })).to eq(user)
    end

    it 'retrieves user by name param' do
      expect(User.from_params({ user: { name: 'usman' } })).to eq(user)
    end
  end

  describe '#fullname' do
    let!(:user) { User.create!(name: 'ali', full_name: 'Ali G', email: 'ali@email.com', password: 'password', role: role) }

    before do
      $redis = double('Redis', get: '')
    end

    it 'returns actual full name if not anonymized' do
      expect(user.fullname).to eq('Ali G')
    end

    it 'returns anonymized name if IP is flagged' do
      allow($redis).to receive(:get).and_return('1.2.3.4')
      expect(user.fullname('1.2.3.4')).to eq('Student, ' + user.id.to_s)
    end
  end

  describe '#as_json' do
    let!(:user) { User.create!(name: 'ricky', full_name: 'Ricky Bob', email: 'ricky@example.com', password: 'password', role: role) }

    it 'serializes essential fields' do
      json = user.as_json
      expect(json['name']).to eq('ricky')
      expect(json['role']).to include('name' => 'Student')
    end
  end
end
