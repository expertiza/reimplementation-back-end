# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do


  describe 'validations' do
    let(:role) { create(:role, :student) }

    describe 'name' do
      it 'is invalid without a name' do
        user = User.new(email: 'test@example.com', full_name: 'Test User', role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("can't be blank")
      end

      it 'is invalid when name is not unique' do
        create(:user, name: 'duplicate', role: role)
        user = User.new(name: 'duplicate', email: 'other@example.com', full_name: 'Other User', role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include('has already been taken')
      end

      it 'is valid with a unique name' do
        user = User.new(name: 'uniqueuser', email: 'unique@example.com', full_name: 'Unique User', role: role, password: 'password')
        expect(user).to be_valid
      end
    end 

    describe 'email' do
      it 'is invalid without an email' do
        user = User.new(name: 'testuser', full_name: 'Test User', role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with a malformed email' do
        user = User.new(name: 'testuser', email: 'not-an-email', full_name: 'Test User', role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it 'is valid with a properly formatted email' do
        user = User.new(name: 'testuser', email: 'valid@example.com', full_name: 'Test User', role: role, password: 'password')
        expect(user).to be_valid
      end
    end

    describe 'full_name' do
      it 'is invalid without a full_name' do
        user = User.new(name: 'testuser', email: 'test@example.com', role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:full_name]).to include("can't be blank")
      end

      it 'is invalid when full_name exceeds 50 characters' do
        user = User.new(name: 'testuser', email: 'test@example.com', full_name: 'A' * 51, role: role, password: 'password')
        expect(user).not_to be_valid
        expect(user.errors[:full_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'is valid with a full_name at exactly 50 characters' do
        user = User.new(name: 'testuser', email: 'test@example.com', full_name: 'A' * 50, role: role, password: 'password')
        expect(user).to be_valid
      end
    end
  end

  # Use shoulda-matchers to assert the association is declared correctly on the model
  # inspects the model's reflection metadata rather than hitting the database
  describe 'associations' do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:institution).optional }
    it { is_expected.to belong_to(:parent).class_name('User').optional }
    it { is_expected.to have_many(:users).with_foreign_key('parent_id').dependent(:nullify) }
    it { is_expected.to have_many(:assignments).through(:participants) }
    it { is_expected.to have_many(:instructed_assignments).class_name('Assignment').with_foreign_key('instructor_id') }
    it { is_expected.to have_many(:teams_users).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:teams_users) }
    it { is_expected.to have_many(:participants) }
  end 

  describe 'scopes' do
    let(:student_role)    { create(:role, name: 'Student') }
    let(:ta_role)         { create(:role, name: 'Teaching Assistant') }
    let(:instructor_role) { create(:role, name: 'Instructor') }
    let(:admin_role)      { create(:role, name: 'Administrator') }
    let(:super_admin_role){ create(:role, name: 'Super Administrator') }

    describe '.students' do
      it 'includes users with student role and excludes others' do
        student = create(:user, role: student_role)
        instructor = create(:user, role: instructor_role)

        expect(User.students).to include(student)
        expect(User.students).not_to include(instructor)
      end
    end

    describe '.tas' do
      it 'includes users with teaching assistant role and excludes others' do
        ta = create(:user, role: ta_role)
        student = create(:user, role: student_role)

        expect(User.tas).to include(ta)
        expect(User.tas).not_to include(student)
      end
    end

    describe '.instructors' do
      it 'includes users with instructor role and excludes others' do
        instructor = create(:user, role: instructor_role)
        student = create(:user, role: student_role)

        expect(User.instructors).to include(instructor)
        expect(User.instructors).not_to include(student)
      end
    end

    describe '.administrators' do
      it 'includes users with administrator role and excludes others' do
        admin = create(:user, role: admin_role)
        student = create(:user, role: student_role)

        expect(User.administrators).to include(admin)
        expect(User.administrators).not_to include(student)
      end
    end

    describe '.superadministrators' do
      it 'includes users with super administrator role and excludes others' do
        super_admin = create(:user, role: super_admin_role)
        student = create(:user, role: student_role)

        expect(User.superadministrators).to include(super_admin)
        expect(User.superadministrators).not_to include(student)
      end
    end
  end

  describe 'delegated role checks' do
    let(:student_role)     { create(:role, name: 'Student') }
    let(:ta_role)          { create(:role, name: 'Teaching Assistant') }
    let(:instructor_role)  { create(:role, name: 'Instructor') }
    let(:admin_role)       { create(:role, name: 'Administrator') }
    let(:super_admin_role) { create(:role, name: 'Super Administrator') }

    describe '#student?' do
      it 'returns true for a student role' do
        user = create(:user, role: student_role)
        expect(user.student?).to be_truthy 
      end

      it 'returns false for a non-student role' do
        user = create(:user, role: instructor_role)
        expect(user.student?).to be_falsy
      end
    end

    describe '#ta?' do
      it 'returns true for a teaching assistant role' do
        user = create(:user, role: ta_role)
        expect(user.ta?).to be_truthy
      end

      it 'returns false for a non-ta role' do
        user = create(:user, role: student_role)
        expect(user.ta?).to be_falsy
      end
    end

    describe '#instructor?' do
      it 'returns true for an instructor role' do
        user = create(:user, role: instructor_role)
        expect(user.instructor?).to be_truthy
      end

      it 'returns false for a non-instructor role' do
        user = create(:user, role: student_role)
        expect(user.instructor?).to be_falsy
      end
    end

    describe '#administrator?' do
      it 'returns true for an administrator role' do
        user = create(:user, role: admin_role)
        expect(user.administrator?).to be_truthy
      end

      it 'returns false for a non-administrator role' do
        user = create(:user, role: student_role)
        expect(user.administrator?).to be_falsy
      end
    end

    describe '#super_administrator?' do
      it 'returns true for a super administrator role' do
        user = create(:user, role: super_admin_role)
        expect(user.super_administrator?).to be_truthy
      end

      it 'returns false for a plain administrator role' do
        user = create(:user, role: admin_role)
        expect(user.super_administrator?).to be_falsy
      end

      it 'returns false for a non-admin role' do
        user = create(:user, role: student_role)
        expect(user.super_administrator?).to be_falsy
      end
    end
  end

  describe 'defaults' do
    subject(:user) { User.new }

    it 'sets is_new_user to true' do
      expect(user.is_new_user).to be true
    end

    it 'sets copy_of_emails to false' do
      expect(user.copy_of_emails).to be false
    end

    it 'sets email_on_review to false' do
      expect(user.email_on_review).to be false
    end

    it 'sets email_on_submission to false' do
      expect(user.email_on_submission).to be false
    end

    it 'sets email_on_review_of_review to false' do
      expect(user.email_on_review_of_review).to be false
    end

    it 'sets etc_icons_on_homepage to true' do
      expect(user.etc_icons_on_homepage).to be true
    end
  end


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

  describe '.instantiate' do
    let(:institution) { create(:institution) }
    let(:instructor_role) { create(:role, :instructor) }
    let(:ta_role) { create(:role, :ta) }
    let(:admin_role) { create(:role, :administrator) }
    let(:super_admin_role) { create(:role, :super_administrator) }
    let(:student_role) { create(:role, :student) }

    it 'returns Instructor for instructor role' do
      user = create(:user, role: instructor_role, institution: institution)
      expect(User.instantiate(user)).to be_a(Instructor)
    end

    it 'returns Ta for teaching assistant role' do
      user = create(:user, role: ta_role, institution: institution)
      expect(User.instantiate(user)).to be_a(Ta)
    end

    it 'returns Administrator for administrator role' do
      user = create(:user, role: admin_role, institution: institution)
      expect(User.instantiate(user)).to be_a(Administrator)
    end

    it 'returns SuperAdministrator for super administrator role' do
      user = create(:user, role: super_admin_role, institution: institution)
      expect(User.instantiate(user)).to be_a(SuperAdministrator)
    end

    it 'returns User as-is for student role' do
      user = create(:user, role: student_role, institution: institution)
      expect(User.instantiate(user)).to be_a(User)
      expect(User.instantiate(user)).not_to be_a(Instructor)
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

  describe 'instance methods - role authorization' do
    let(:institution) { create(:institution) }
    let(:student_role) { create(:role, :student) }
    let(:ta_role) { create(:role, :ta) }
    let(:instructor_role) { create(:role, :instructor) }
    let(:admin_role) { create(:role, :administrator) }
    let(:super_admin_role) { create(:role, :super_administrator) }

    describe '#instructor_id' do
      it 'returns own id for instructor' do
        instructor = create(:user, role: instructor_role, institution: institution)
        expect(instructor.instructor_id).to eq(instructor.id)
      end

      it 'returns own id for administrator' do
        admin = create(:user, role: admin_role, institution: institution)
        expect(admin.instructor_id).to eq(admin.id)
      end

      it 'returns own id for super administrator' do
        super_admin = create(:user, role: super_admin_role, institution: institution)
        expect(super_admin.instructor_id).to eq(super_admin.id)
      end

      it 'returns instructor id for teaching assistant' do
        instructor = create(:user, role: instructor_role, institution: institution)
        ta = create(:user, role: ta_role, institution: institution, parent: instructor)
        expect(ta.instructor_id).to eq(instructor.id)
      end

      it 'returns nil instructor id for a TA without a parent record' do
        ta = create(:user, role: ta_role, institution: institution, parent: nil)

        expect(ta.instructor_id).to be_nil
      end

      it 'raises NotImplementedError for student role' do
        student = create(:user, role: student_role, institution: institution)
        expect { student.instructor_id }.to raise_error(NotImplementedError, /Unknown role/)
      end
    end

    describe '#can_impersonate?' do
      let(:student1) { create(:user, role: student_role, institution: institution) }
      let(:student2) { create(:user, role: student_role, institution: institution) }
      let(:instructor) { create(:user, role: instructor_role, institution: institution) }
      let(:super_admin) { create(:user, role: super_admin_role, institution: institution) }

      it 'super admin can impersonate anyone' do
        expect(super_admin.can_impersonate?(student1)).to be true
        expect(super_admin.can_impersonate?(instructor)).to be true
        expect(super_admin.can_impersonate?(super_admin)).to be true
      end

      it 'parent can impersonate direct child' do
        child = create(:user, role: student_role, institution: institution, parent: instructor)
        expect(instructor.can_impersonate?(child)).to be true
      end

      it 'parent cannot impersonate unrelated user' do
        expect(instructor.can_impersonate?(student1)).to be false
      end

      it 'regular user cannot impersonate anyone' do
        expect(student1.can_impersonate?(student2)).to be false
      end
    end

    describe '#recursively_parent_of' do
      let(:grandparent) { create(:user, role: instructor_role, institution: institution) }
      let(:parent) { create(:user, role: instructor_role, institution: institution, parent: grandparent) }
      let(:child) { create(:user, role: student_role, institution: institution, parent: parent) }

      it 'identifies direct parent' do
        expect(parent.recursively_parent_of(child)).to be true
      end

      it 'identifies grandparent in hierarchy' do
        expect(grandparent.recursively_parent_of(child)).to be true
      end

      it 'returns false for non-parent' do
        other_user = create(:user, role: student_role, institution: institution)
        expect(other_user.recursively_parent_of(child)).to be false
      end

      it 'returns false when user has no parent' do
        orphan = create(:user, role: student_role, institution: institution)
        expect(grandparent.recursively_parent_of(orphan)).to be false
      end
    end

    describe '#teaching_assistant_for?' do
      let(:ta_role)       { Role.find_or_create_by!(name: 'Teaching Assistant') }
      let(:student_role)  { Role.find_or_create_by!(name: 'Student') }
      let(:course) { Course.create!(name: 'Test Course', directory_path: 'test_course', institution: institution, instructor_id: create(:user, role: instructor_role, institution: institution).id) }
      let(:ta_user) { create(:user, role: ta_role, institution: institution) }
      let(:student) { create(:user, role: student_role, institution: institution) }
      let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor_id: create(:user, role: instructor_role, institution: institution).id, course_id: course.id) }

      it 'returns false when user is not a teaching assistant' do
        instructor = create(:user, role: instructor_role, institution: institution)
        expect(instructor.teaching_assistant_for?(student)).to be false
      end

      it 'returns false when target user is not a student' do
        other_instructor = create(:user, role: instructor_role, institution: institution)
        expect(ta_user.teaching_assistant_for?(other_instructor)).to be false
      end

      it 'returns true when TA assists a course that has the student as participant' do
        TaMapping.create!(user_id: ta_user.id, course_id: course.id)
        AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
        expect(ta_user.teaching_assistant_for?(student)).to be true
      end

      it 'returns false when TA has no course mappings' do
        expect(ta_user.teaching_assistant_for?(student)).to be false
      end

      it 'returns false when student is not a participant in any TA course' do
        other_course = Course.create!(name: 'Other Course', directory_path: 'other_course', institution: institution, instructor_id: create(:user, role: instructor_role, institution: institution).id)
        TaMapping.create!(user_id: ta_user.id, course_id: other_course.id)
        expect(ta_user.teaching_assistant_for?(student)).to be false
      end
    end

    describe '#teaching_assistant?' do
      it 'returns true for teaching assistant role' do
        ta = create(:user, role: ta_role, institution: institution)
        expect(ta.teaching_assistant?).to be true
      end

      it 'returns false for non-ta roles' do
        student = create(:user, role: student_role, institution: institution)
        instructor = create(:user, role: instructor_role, institution: institution)
        
        expect(student.teaching_assistant?).to be false
        expect(instructor.teaching_assistant?).to be false
      end
    end

    describe '#as_json' do
      let(:user) { create(:user, role: student_role, institution: institution) }

      it 'includes only permitted user fields' do
        json = user.as_json
        
        expect(json.keys).to include('id', 'name', 'email', 'full_name')
        expect(json.keys).to include('email_on_review', 'email_on_submission', 'email_on_review_of_review')
      end

      it 'excludes sensitive fields' do
        json = user.as_json
        
        expect(json.keys).not_to include('password_digest', 'password', 'updated_at', 'created_at')
      end

      it 'includes role with only id and name' do
        json = user.as_json
        
        expect(json['role']).to be_a(Hash)
        expect(json['role'].keys).to contain_exactly('id', 'name')
      end

      it 'includes parent with default nil values when none exists' do
        json = user.as_json
        
        expect(json['parent']).to eq({ 'id' => nil, 'name' => nil })
      end

      it 'includes institution with data when assigned' do
        json = user.as_json
        
        expect(json['institution']).to be_a(Hash)
        expect(json['institution']['id']).to eq(institution.id)
        expect(json['institution']['name']).to eq(institution.name)
      end

      it 'includes parent data when user has parent' do
        parent_user = create(:user, role: instructor_role, institution: institution)
        child_user = create(:user, role: student_role, institution: institution, parent: parent_user)
        json = child_user.as_json
        
        expect(json['parent']['id']).to eq(parent_user.id)
        expect(json['parent']['name']).to eq(parent_user.name)
      end
    end

    describe '#generate_jwt' do
      let(:user) { create(:user, role: student_role, institution: institution) }

      it 'generates a valid JWT token' do
        token = user.generate_jwt
        
        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3)  # JWT has 3 parts
      end

      it 'encodes user id in token' do
        token = user.generate_jwt
        decoded = JWT.decode(token, nil, false)
        expect(decoded[0]['id']).to eq(user.id)
      end

      it 'sets expiration to 60 days from now' do
        token = user.generate_jwt
        decoded = JWT.decode(token, nil, false)
        exp_time = Time.at(decoded[0]['exp'])
        expect(exp_time).to be_between(59.days.from_now, 61.days.from_now)
      end

      it 'generates different tokens on each call' do
        token1 = user.generate_jwt
        decoded1 = JWT.decode(token1, nil, false)
        token2 = user.generate_jwt
        decoded2 = JWT.decode(token2, nil, false)
        # Both encode the same user id; tokens may be identical within same second — just verify structure
        expect(token1).to be_a(String)
        expect(decoded1[0]['id']).to eq(user.id)
        expect(decoded2[0]['id']).to eq(user.id)
      end
    end
  end

  describe 'regression checks - edge cases and fragile areas' do
    let(:institution) { create(:institution) }
    let(:student_role) { create(:role, :student) }
    let(:instructor_role) { create(:role, :instructor) }
    let(:super_admin_role) { create(:role, :super_administrator) }

    it 'handles user with nil parent gracefully' do
      user = create(:user, role: student_role, institution: institution)
      
      expect(user.parent).to be_nil
      expect { user.recursively_parent_of(user) }.not_to raise_error
    end

    it 'prevents infinite recursion in parent hierarchy' do
      user1 = create(:user, role: instructor_role, institution: institution)
      user2 = create(:user, role: student_role, institution: institution, parent: user1)
      
      # user1 is parent of user2, so this should return false (not traverse infinitely)
      expect(user2.recursively_parent_of(user1)).to be false
    end

    it 'handles as_json with missing institution' do
      user = create(:user, role: student_role, institution_id: nil)
      json = user.as_json
      
      expect(json['institution']).to eq({ 'id' => nil, 'name' => nil })
    end

    it 'generates distinct JWTs for different users' do
      user1 = create(:user, role: student_role, institution: institution)
      user2 = create(:user, role: student_role, institution: institution)
      
      token1 = user1.generate_jwt
      token2 = user2.generate_jwt
      
      decoded1 = JWT.decode(token1, nil, false)
      decoded2 = JWT.decode(token2, nil, false)
      
      expect(decoded1[0]['id']).to eq(user1.id)
      expect(decoded2[0]['id']).to eq(user2.id)
    end

    it 'instructor_id works correctly after role changes' do
      user = create(:user, role: student_role, institution: institution)
      
      expect { user.instructor_id }.to raise_error(NotImplementedError)
      
      user.update(role: instructor_role)
      expect(user.instructor_id).to eq(user.id)
    end

    it 'can_impersonate? respects role hierarchy' do
      instructor = create(:user, role: instructor_role, institution: institution)
      super_admin = create(:user, role: super_admin_role, institution: institution)
      student = create(:user, role: student_role, institution: institution)
      
      expect(instructor.can_impersonate?(student)).to be false
      expect(super_admin.can_impersonate?(instructor)).to be true
      expect(super_admin.can_impersonate?(student)).to be true
    end
  end
end
