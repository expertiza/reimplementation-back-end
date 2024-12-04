require 'rails_helper'

RSpec.describe Authorization, type: :controller do
  controller(ApplicationController) do
    include Authorization
  end

  # Global test doubles and setup
  let(:user) { instance_double('User') }
  let(:role) { instance_double('Role') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(user).to receive(:role).and_return(role)
  end

  ##########################################
  # Tests for has_required_role? method
  ##########################################
  describe '#has_required_role?' do
    describe 'role validation' do
      context 'when required_role is a string' do
        let(:admin_role) { instance_double('Role') }

        before do
          allow(Role).to receive(:find_by_name).with('Administrator').and_return(admin_role)
        end

        it 'finds the role and checks privileges' do
          expect(role).to receive(:all_privileges_of?).with(admin_role).and_return(true)
          expect(controller.has_required_role?('Administrator')).to be true
        end
      end

      context 'when required_role is a Role object' do
        let(:instructor_role) { instance_double('Role') }

        it 'directly checks privileges' do
          expect(role).to receive(:all_privileges_of?).with(instructor_role).and_return(false)
          expect(controller.has_required_role?(instructor_role)).to be false
        end
      end
    end

    describe 'edge cases' do
      context 'when user is not logged in' do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end

        it 'returns false' do
          expect(controller.has_required_role?('Administrator')).to be false
        end
      end

      context 'when user has no role' do
        before do
          allow(user).to receive(:role).and_return(nil)
        end

        it 'returns false' do
          expect(controller.has_required_role?('Administrator')).to be false
        end
      end
    end
  end

  ##########################################
  # Tests for is_role? method
  ##########################################
  describe '#is_role?' do
    describe 'role matching' do
      context 'when role_name is a string' do
        before do
          allow(role).to receive(:name).and_return('Student')
        end

        it 'returns true when roles match' do
          expect(controller.is_role?('Student')).to be true
        end

        it 'returns false when roles do not match' do
          expect(controller.is_role?('Instructor')).to be false
        end
      end

      context 'when role_name is a Role object' do
        let(:role_object) { instance_double('Role', name: 'Student') }

        before do
          allow(role).to receive(:name).and_return('Student')
          allow(role_object).to receive(:name).and_return('Student')
          allow(role_object).to receive(:is_a?).with(Role).and_return(true)
        end

        it 'compares using the role name' do
          expect(controller.is_role?(role_object)).to be true
        end
      end
    end

    describe 'edge cases' do
      context 'when user is not logged in' do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end

        it 'returns false' do
          expect(controller.is_role?('Student')).to be false
        end
      end

      context 'when user has no role' do
        before do
          allow(user).to receive(:role).and_return(nil)
        end

        it 'returns false' do
          expect(controller.is_role?('Student')).to be false
        end
      end
    end
  end
  
  ##########################################
  # Tests for all_actions_allowed? method
  ##########################################
  describe '#all_actions_allowed?' do
    context 'when the user has the Administrator role' do
      before do
        allow(controller).to receive(:has_required_role?).with('Administrator').and_return(true)
      end

      it 'returns true' do
        expect(controller.all_actions_allowed?).to be true
      end
    end

    context 'when the user does not have the Administrator role' do
      before do
        allow(controller).to receive(:has_required_role?).with('Administrator').and_return(false)
        allow(controller).to receive(:action_allowed?).and_return(false)
      end

      it 'checks action_allowed? and returns false' do
        expect(controller.all_actions_allowed?).to be false
      end
    end

    context 'when action_allowed? returns true' do
      before do
        allow(controller).to receive(:has_required_role?).with('Administrator').and_return(false)
        allow(controller).to receive(:action_allowed?).and_return(true)
      end

      it 'returns true' do
        expect(controller.all_actions_allowed?).to be true
      end
    end
  end

  ##########################################
  # Tests for action_allowed? method
  ##########################################
  describe '#action_allowed?' do
    it 'returns true by default' do
      expect(controller.action_allowed?).to be true
    end

    it 'can be overridden in subclasses for custom logic' do
      class CustomController < ApplicationController
        include Authorization

        def action_allowed?
          false
        end
      end

      custom_controller = CustomController.new
      expect(custom_controller.action_allowed?).to be false
    end
  end

  ##########################################
  # Tests for authorize method
  ##########################################
  describe '#authorize' do
    context 'when all actions are allowed' do
      before do
        allow(controller).to receive(:all_actions_allowed?).and_return(true)
      end

      it 'does not render an error response' do
        expect(controller).not_to receive(:render)
        controller.authorize
      end
    end

    context 'when actions are not allowed' do
      before do
        allow(controller).to receive(:all_actions_allowed?).and_return(false)
        allow(controller.params).to receive(:[]).with(:action).and_return('edit')
        allow(controller.params).to receive(:[]).with(:controller).and_return('users')
      end

      it 'renders an error response with forbidden status' do
        expect(controller).to receive(:render).with(
          json: { error: "You are not authorized to edit this users" },
          status: :forbidden
        )
        controller.authorize
      end
    end
  end
end
