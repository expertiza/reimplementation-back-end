# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentSerializer, type: :serializer do
  include RolesHelper

  before(:each) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NCSU Serializer Test') }
  let(:instructor) do
    User.create!(name: 'serializer_instructor', full_name: 'Serializer Instructor',
                 email: 'serializer@example.com', password_digest: 'password',
                 role_id: @roles[:instructor].id, institution_id: institution.id)
  end

  def serialized(assignment)
    JSON.parse(AssignmentSerializer.new(assignment).to_json)
  end

  # -----------------------------------------------------------------------
  # is_penalty_calculated / apply_late_policy
  # -----------------------------------------------------------------------
  describe 'late penalty fields' do
    it 'includes is_penalty_calculated in the serialized output' do
      assignment = Assignment.create!(name: 'Penalty Test', instructor: instructor,
                                      is_penalty_calculated: true)
      json = serialized(assignment)
      expect(json['is_penalty_calculated']).to be true
    end

    it 'does NOT include apply_late_policy (virtual attr_writer has no DB column)' do
      assignment = Assignment.create!(name: 'Virtual Penalty', instructor: instructor)
      json = serialized(assignment)
      expect(json.key?('apply_late_policy')).to be false
    end

    it 'is_penalty_calculated persists correctly when updated' do
      assignment = Assignment.create!(name: 'Persist Penalty', instructor: instructor,
                                      is_penalty_calculated: false)
      assignment.update!(is_penalty_calculated: true)
      json = serialized(assignment.reload)
      expect(json['is_penalty_calculated']).to be true
    end
  end

  # -----------------------------------------------------------------------
  # set_allowed_number_of_reviews_per_reviewer / has_max_review_limit
  # -----------------------------------------------------------------------
  describe 'review limit fields' do
    it 'includes set_allowed_number_of_reviews_per_reviewer in the serialized output' do
      assignment = Assignment.create!(name: 'Review Limit', instructor: instructor,
                                      num_reviews_allowed: 5)
      json = serialized(assignment)
      expect(json['set_allowed_number_of_reviews_per_reviewer']).to eq(5)
    end

    it 'does NOT include has_max_review_limit (virtual attr_writer, not a DB column)' do
      assignment = Assignment.create!(name: 'No Max Limit Field', instructor: instructor)
      json = serialized(assignment)
      expect(json.key?('has_max_review_limit')).to be false
    end

    it 'set_allowed_number_of_reviews_per_reviewer is 0 when no limit is configured' do
      assignment = Assignment.create!(name: 'Zero Limit', instructor: instructor,
                                      num_reviews_allowed: 0)
      json = serialized(assignment)
      expect(json['set_allowed_number_of_reviews_per_reviewer']).to eq(0)
    end
  end

  # -----------------------------------------------------------------------
  # due_dates: deadline_name for named deadlines
  # -----------------------------------------------------------------------
  describe 'due_dates with named deadlines' do
    it 'includes deadline_name = drop_topic for type id 7' do
      assignment = Assignment.create!(name: 'Drop Topic', instructor: instructor)
      AssignmentDueDate.create!(parent: assignment,
                                due_at: 1.week.from_now,
                                deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
                                submission_allowed_id: 3, review_allowed_id: 3)
      json = serialized(assignment)
      drop = json['due_dates'].find { |d| d['deadline_type_id'] == ExpertizaConstants::DeadlineTypes::DROP_TOPIC }
      expect(drop).not_to be_nil
      expect(drop['deadline_name']).to eq('drop_topic')
    end

    it 'includes deadline_name = team_formation for type id 9' do
      assignment = Assignment.create!(name: 'Team Formation', instructor: instructor)
      AssignmentDueDate.create!(parent: assignment,
                                due_at: 1.week.from_now,
                                deadline_type_id: ExpertizaConstants::DeadlineTypes::TEAM_FORMATION,
                                submission_allowed_id: 3, review_allowed_id: 3)
      json = serialized(assignment)
      tf = json['due_dates'].find { |d| d['deadline_type_id'] == ExpertizaConstants::DeadlineTypes::TEAM_FORMATION }
      expect(tf).not_to be_nil
      expect(tf['deadline_name']).to eq('team_formation')
    end

    it 'includes deadline_name = signup for type id 8' do
      assignment = Assignment.create!(name: 'Signup', instructor: instructor)
      AssignmentDueDate.create!(parent: assignment,
                                due_at: 1.week.from_now,
                                deadline_type_id: ExpertizaConstants::DeadlineTypes::SIGNUP,
                                submission_allowed_id: 3, review_allowed_id: 3)
      json = serialized(assignment)
      su = json['due_dates'].find { |d| d['deadline_type_id'] == ExpertizaConstants::DeadlineTypes::SIGNUP }
      expect(su).not_to be_nil
      expect(su['deadline_name']).to eq('signup')
    end
  end
end
