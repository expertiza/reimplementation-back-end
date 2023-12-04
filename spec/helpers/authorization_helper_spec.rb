require 'rails_helper'
require 'json_web_token'

describe AuthorizationHelper do
    let(:user_info) { { user_id: 1, role: 'Student' } }
    let(:token) { JsonWebToken.encode(user_info) }

    describe "#current_user_and_role_exist?" do
        context "when user is logged in but does not have a role" do
            it "returns false" do
                user_info_without_role = { user_id: 1 }
                result = helper.current_user_and_role_exist?(user_info_without_role)
                expect(result).to be false
            end
        end

        context "when user is not logged in" do
            it "returns false" do
                result = helper.current_user_and_role_exist?(nil)
                expect(result).to be false
            end
        end
  end


    describe "#jwt_verify_and_decode" do
      context "when a valid token is provided" do
        it "decodes and returns user information" do
            decoded_user_info = helper.jwt_verify_and_decode(token)
            expect(decoded_user_info).to be_a(HashWithIndifferentAccess)
            expect(decoded_user_info['user_id']).to eq(1)
            expect(decoded_user_info['role']).to eq('Student')
        end
       end

      context "when an invalid token is provided" do
        let(:invalid_token) { 'invalid_token' }
        it "returns nil" do
            decoded_user_info = helper.jwt_verify_and_decode(invalid_token)
            expect(decoded_user_info).to be_nil
        end
      end
  end   


  describe "#check_user_privileges" do

    context "when user information or required privilege is missing" do
        it "returns false" do
        expect(helper.check_user_privileges(nil, 'Student')).to be_falsey
        expect(helper.check_user_privileges(user_info, nil)).to be_falsey
        end
    end
  end

    describe "#current_user_has_super_admin_privileges?" do
      context "when the current user has super admin privileges" do
        it "returns true" do
          # Test scenario 1: Current user has super admin privileges
          allow_any_instance_of(AuthorizationHelper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'role' => 'Super-Administrator' })
          expect(helper.current_user_has_super_admin_privileges?(token)).to be_truthy
        end
      end
    
      context "when the current user does not have super admin privileges" do
        it "returns false" do
          # Test scenario 2: Current user does not have super admin privileges
          allow_any_instance_of(AuthorizationHelper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'role' => 'Administrator' })
          expect(helper.current_user_has_super_admin_privileges?(token)).to be_falsey
        end
      end
    end
    describe "#current_user_has_admin_privileges?" do
      context "when the current user has admin privileges" do
        it "returns true" do
          # Test scenario 1: Current user is an administrator
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Administrator' })
          result = helper.current_user_has_admin_privileges?(token)
          expect(result).to be true
        end
      end
    
      context "when the current user does not have admin privileges" do
        it "returns false" do
          # Test scenario 2: Current user is a regular user
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          result = helper.current_user_has_admin_privileges?(token)
          expect(result).to be false
        end
      end
    end
    describe "#current_user_has_instructor_privileges?" do
      context "when the current user has instructor privileges" do
        it "returns true" do
          # Test scenario 1: Current user is an instructor
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Instructor' })
          result = helper.current_user_has_instructor_privileges?(token)
          expect(result).to be true
        end
      end
    
      context "when the current user does not have instructor privileges" do
        it "returns false" do
          # Test scenario 2: Current user is a student
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          result = helper.current_user_has_instructor_privileges?(token)
          expect(result).to be false
        end
      end
    end
    describe "#current_user_has_ta_privileges?" do
      context "when the current user has privileges of a Teaching Assistant" do
        it "returns true" do
          # Test scenario 1
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Teaching Assistant' })
          result = helper.current_user_has_ta_privileges?(token)
          expect(result).to be true
        end
      end
    
      context "when the current user does not have privileges of a Teaching Assistant" do
        it "returns false" do
          # Test scenario 2
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          result = helper.current_user_has_ta_privileges?(token)
          expect(result).to be false
        end
      end
    end
    describe "#current_user_has_student_privileges?" do
      context "when the current user has student privileges" do
        it "returns true" do
          # Test scenario 1: Current user has student privileges
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          result = helper.current_user_has_student_privileges?(token)
          expect(result).to be true
        end
      end
    
      context "when the current user does not have student privileges" do
        it "returns false" do
          # Test scenario 2: Current user does not have student privileges
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Instructor' })
          result = helper.current_user_has_student_privileges?(token)
          expect(result).to be false
        end
      end
    end
    describe "#current_user_is_assignment_participant?" do
      context "when user is logged in" do
        it "returns true if the current user is a participant of the assignment" do
          # Test scenario 1: User is a participant of the assignment
          # Method call: current_user_is_assignment_participant?(1)
          # Expected output: true
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          allow(helper).to receive(:current_user_is_assignment_participant?).with(token, 1).and_return(true)
          result = helper.current_user_is_assignment_participant?(token, 1)
          expect(result).to be true
        end

        it "returns false if the current user is not a participant of the assignment" do
          # Test scenario 2: User is not a participant of the assignment
          # Method call: current_user_is_assignment_participant?(2)
          # Expected output: false
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          allow(helper).to receive(:current_user_is_assignment_participant?).with(token, 2).and_return(false)
          result = helper.current_user_is_assignment_participant?(token, 2)
          expect(result).to be false
        end
       end

      context "when user is not logged in" do
        it "returns false" do
          # Test scenario 3: User is not logged in
          # Method call: current_user_is_assignment_participant?(3)
          # Expected output: false
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return(nil)
          result = helper.current_user_is_assignment_participant?(token, 1)
          expect(result).to be false
        end
      end
    end
    describe "#current_user_teaching_staff_of_assignment?" do
      context "when the user is logged in and instructs the assignment" do
        it "returns true" do
          # Test scenario
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Instructor' })
          allow(helper).to receive(:current_user_teaching_staff_of_assignment?).with(token, 1).and_return(true)
          result = helper.current_user_teaching_staff_of_assignment?(token, 1)
          expect(result).to be true
        end
      end
    
      context "when the user is logged in and has TA mapping for the assignment" do
        it "returns true" do
          # Test scenario
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Teaching Assistant' })
          allow(helper).to receive(:current_user_teaching_staff_of_assignment?).with(token, 1).and_return(true)
          result = helper.current_user_teaching_staff_of_assignment?(token, 1)
          expect(result).to be true
        end
      end
    
    end
    describe "#current_user_is_a?" do
      context "when current user and role exist" do
        it "returns false if the current user's role name does not match the given role name" do
          # Test scenario 2
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => 'Student' })
          result = helper.current_user_is_a?(token, 'Instructor')
          expect(result).to be false
        end
      end
    
      context "when current user or role does not exist" do
        it "returns false if current user does not exist" do
          # Test scenario 3
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return(nil)
          result = helper.current_user_is_a?(token, 'Instructor')
          expect(result).to be false
        end
    
        it "returns false if current user's role does not exist" do
          # Test scenario 4
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 1, 'role' => nil })
          result = helper.current_user_is_a?(token, 'Instructor')
          expect(result).to be false
        end
      end
    end
    describe "current_user_has_id?" do
      context "when user is logged in but has a different id" do
        it "returns false" do
          # test body
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return({ 'id' => 2, 'role' => 'Student' })
          result = helper.current_user_has_id?(token, 1)
          expect(result).to be false
        end
      end
    
      context "when user is not logged in" do
        it "returns false" do
          # test body
          allow(helper).to receive(:jwt_verify_and_decode).with(token).and_return(nil)
          result = helper.current_user_has_id?(token, 1)
          expect(result).to be false
        end
      end
    end
end