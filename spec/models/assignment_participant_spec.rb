# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentParticipant, type: :model do
  describe '#timeline_events' do
    let!(:assignment)  { create(:assignment) }
    let!(:participant) { create(:assignment_participant, assignment: assignment) }

    it "includes due dates with id: nil" do
      DueDate.create!(parent: assignment, due_at: 7.days.from_now, deadline_name: 'Submission',
                      deadline_type_id: 1, submission_allowed_id: 3, review_allowed_id: 3)
      review_relation = double('relation')
      allow(review_relation).to receive(:find_each)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)
      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      timeline = participant.timeline_events
      submission_entry = timeline.find { |t| t['name'].include?('Submission') }
      expect(submission_entry).not_to be_nil
      expect(submission_entry['id']).to be_nil
    end

    it "includes submitted peer review responses with a real id" do
      map = double('map', id: 1)
      submitted_response = double('response', id: 99, round: 1, updated_at: 2.days.ago)

      review_relation = double('relation')
      allow(review_relation).to receive(:find_each).and_yield(map)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)

      ordered_scope = double('ordered_scope')
      allow(ordered_scope).to receive(:each).and_yield(submitted_response)
      allow(ordered_scope).to receive(:order).with(updated_at: :desc).and_return(ordered_scope)
      allow(Response).to receive(:where).with(map_id: 1, is_submitted: true).and_return(ordered_scope)

      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      timeline = participant.timeline_events
      review_entry = timeline.find { |t| t['name'].include?('peer review') }
      expect(review_entry).not_to be_nil
      expect(review_entry['id']).to eq(99)
    end

    it "excludes unsubmitted/draft peer review responses from the timeline" do
      map = double('map', id: 1)

      review_relation = double('relation')
      allow(review_relation).to receive(:find_each).and_yield(map)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)

      empty_ordered = double('empty_ordered')
      allow(empty_ordered).to receive(:each)
      allow(empty_ordered).to receive(:order).with(updated_at: :desc).and_return(empty_ordered)
      allow(Response).to receive(:where).with(map_id: 1, is_submitted: true).and_return(empty_ordered)

      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      timeline = participant.timeline_events
      expect(timeline.any? { |t| t['name'].include?('peer review') }).to be false
    end

    it "captures both round 1 and round 2 responses for the same map" do
      map = double('map', id: 1)
      r1 = double('r1', id: 10, round: 1, updated_at: 10.days.ago)
      r2 = double('r2', id: 11, round: 2, updated_at: 3.days.ago)

      review_relation = double('relation')
      allow(review_relation).to receive(:find_each).and_yield(map)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)

      ordered_scope = double('ordered_scope')
      allow(ordered_scope).to receive(:each).and_yield(r1).and_yield(r2)
      allow(ordered_scope).to receive(:order).with(updated_at: :desc).and_return(ordered_scope)
      allow(Response).to receive(:where).with(map_id: 1, is_submitted: true).and_return(ordered_scope)

      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      timeline = participant.timeline_events
      review_entries = timeline.select { |t| t['name'].include?('peer review') }
      expect(review_entries.map { |e| e['round'] }).to contain_exactly(1, 2)
    end

    it "excludes unsubmitted author feedback responses" do
      map = double('map', id: 2)

      review_relation = double('relation')
      allow(review_relation).to receive(:find_each)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)

      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each).and_yield(map)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      ordered = double('ordered')
      allow(ordered).to receive(:first).and_return(nil)
      allow(Response).to receive(:where).with(map_id: 2, is_submitted: true).and_return(double(order: ordered))

      timeline = participant.timeline_events
      expect(timeline.any? { |t| t['name'] == 'Author feedback' }).to be false
    end

    it "returns entries sorted by date" do
      DueDate.create!(parent: assignment, due_at: 7.days.from_now, deadline_name: 'Submission',
                      deadline_type_id: 1, submission_allowed_id: 3, review_allowed_id: 3)
      DueDate.create!(parent: assignment, due_at: 14.days.from_now, deadline_name: 'Review',
                      deadline_type_id: 2, submission_allowed_id: 3, review_allowed_id: 3)

      review_relation = double('relation')
      allow(review_relation).to receive(:find_each)
      allow(ReviewResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(review_relation)
      feedback_relation = double('feedback_relation')
      allow(feedback_relation).to receive(:find_each)
      allow(FeedbackResponseMap).to receive(:where).with(reviewer_id: participant.id).and_return(feedback_relation)

      timeline = participant.timeline_events
      dates = timeline.map { |t| t['date'] }
      expect(dates).to eq(dates.sort)
    end
  end

  describe '.all_teammates' do
    let!(:assignment) { create(:assignment, :with_course, is_calibrated: false) }
    let!(:user)       { create(:user) }
    let!(:teammate)   { create(:user) }

    def add_to_team(team, u, asgn)
      TeamsUser.create!(team_id: team.id, user_id: u.id)
      participant = AssignmentParticipant.find_or_create_by!(user_id: u.id, parent_id: asgn.id) do |p|
        p.handle = u.name
      end
      TeamsParticipant.find_or_create_by!(team_id: team.id, user_id: u.id, participant_id: participant.id)
    end

    it "returns teammates grouped by course name" do
      team = AssignmentTeam.create!(name: 'AP Team 1', parent_id: assignment.id)
      add_to_team(team, user, assignment)
      add_to_team(team, teammate, assignment)

      result = AssignmentParticipant.all_teammates(user)
      expect(result).to have_key(assignment.course.name)
      expect(result[assignment.course.name]).to include(teammate.full_name)
    end

    it "excludes calibrated assignments" do
      calibrated = create(:assignment, :with_course)
      calibrated.update_columns(is_calibrated: true)
      team = AssignmentTeam.create!(name: 'AP Team Cal', parent_id: calibrated.id)
      add_to_team(team, user, calibrated)
      add_to_team(team, teammate, calibrated)

      result = AssignmentParticipant.all_teammates(user)
      expect(result.values.flatten).not_to include(teammate.full_name)
    end

    it "excludes the user themselves from teammates" do
      team = AssignmentTeam.create!(name: 'AP Team Solo', parent_id: assignment.id)
      add_to_team(team, user, assignment)

      result = AssignmentParticipant.all_teammates(user)
      expect(result).to be_empty
    end

    it "returns teammates sorted alphabetically" do
      student3 = create(:user)
      team = AssignmentTeam.create!(name: 'AP Team Sort', parent_id: assignment.id)
      add_to_team(team, user, assignment)
      add_to_team(team, teammate, assignment)
      add_to_team(team, student3, assignment)

      result = AssignmentParticipant.all_teammates(user)
      course_name = assignment.course.name
      expect(result[course_name]).to eq(result[course_name].sort)
    end
  end
end
