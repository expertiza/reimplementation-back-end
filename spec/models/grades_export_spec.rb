# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe Grades, type: :model do
  describe 'grade export' do
    def create_scored_response(map:, item:, score:, comments:, round: 1)
      response = Response.create!(
        map_id: map.id,
        additional_comment: comments,
        is_submitted: true,
        round: round
      )

      Answer.create!(
        response: response,
        item: item,
        answer: score,
        comments: comments
      )

      response
    end

    it 'exports one csv row per participant with the expected grades columns' do
      instructor = Instructor.create!(
        name: 'gradesinstructor',
        email: 'gradesinstructor@example.com',
        full_name: 'Grades Instructor',
        password: 'password',
        role: create(:role, :instructor),
        institution: create(:institution)
      )
      assignment = create(:assignment, instructor: instructor, name: 'Grades Export Assignment')
      non_clashing_assignment_id = [
        Assignment.maximum(:id),
        ResponseMap.maximum(:id),
        Response.maximum(:id)
      ].compact.max.to_i + 10_000
      assignment.update_column(:id, non_clashing_assignment_id)
      assignment.reload

      questionnaire = Questionnaire.create!(
        name: 'Grades Export Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'instructions'
      )

      item = Item.create!(
        questionnaire: questionnaire,
        txt: 'How strong was the work?',
        weight: 1,
        seq: 1,
        question_type: 'Scale',
        break_before: true
      )

      AssignmentQuestionnaire.create!(
        assignment: assignment,
        questionnaire: questionnaire,
        used_in_round: 1,
        notification_limit: 5,
        questionnaire_weight: 100
      )

      alice = create(:user, :student, name: 'alice_export', email: 'alice_export@example.com', full_name: 'Alice Export')
      aaron = create(:user, :student, name: 'aaron_export', email: 'aaron_export@example.com', full_name: 'Aaron Export')
      bella = create(:user, :student, name: 'bella_export', email: 'bella_export@example.com', full_name: 'Bella Export')
      ben = create(:user, :student, name: 'ben_export', email: 'ben_export@example.com', full_name: 'Ben Export')

      participant_a1 = create(:assignment_participant, assignment: assignment, user: alice, handle: alice.name)
      participant_a2 = create(:assignment_participant, assignment: assignment, user: aaron, handle: aaron.name)
      participant_b1 = create(:assignment_participant, assignment: assignment, user: bella, handle: bella.name)
      participant_b2 = create(:assignment_participant, assignment: assignment, user: ben, handle: ben.name)

      team_one = AssignmentTeam.create!(
        name: 'Team One',
        parent_id: assignment.id,
        type: 'AssignmentTeam',
        grade_for_submission: 88
      )
      team_two = AssignmentTeam.create!(
        name: 'Team Two',
        parent_id: assignment.id,
        type: 'AssignmentTeam',
        grade_for_submission: 93
      )

      expect(team_one.add_member(participant_a1)[:success]).to be(true)
      expect(team_one.add_member(participant_a2)[:success]).to be(true)
      expect(team_two.add_member(participant_b1)[:success]).to be(true)
      expect(team_two.add_member(participant_b2)[:success]).to be(true)

      3.times do |index|
        ReviewResponseMap.create!(
          reviewed_object_id: assignment.id,
          reviewer_id: participant_a1.id,
          reviewee_id: team_two.id
        )
        Response.create!(
          map_id: ReviewResponseMap.last.id,
          additional_comment: "throwaway review #{index}",
          is_submitted: true,
          round: 1
        )
      end

      poor_review_map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_a1.id,
        reviewee_id: team_two.id
      )
      good_review_map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_b1.id,
        reviewee_id: team_one.id
      )

      poor_review_response = create_scored_response(
        map: poor_review_map,
        item: item,
        score: 2,
        comments: 'Poor review from Team One to Team Two'
      )
      good_review_response = create_scored_response(
        map: good_review_map,
        item: item,
        score: 9,
        comments: 'Strong review from Team Two to Team One'
      )

      expect(assignment.id).not_to eq(poor_review_map.id)
      expect(assignment.id).not_to eq(good_review_map.id)
      expect(assignment.id).not_to eq(poor_review_response.id)
      expect(assignment.id).not_to eq(good_review_response.id)

      teammate_map_a1 = TeammateReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_a1.id,
        reviewee_id: participant_a2.id
      )
      teammate_map_a2 = TeammateReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_a2.id,
        reviewee_id: participant_a1.id
      )
      teammate_map_b1 = TeammateReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_b1.id,
        reviewee_id: participant_b2.id
      )
      teammate_map_b2 = TeammateReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: participant_b2.id,
        reviewee_id: participant_b1.id
      )

      create_scored_response(map: teammate_map_a1, item: item, score: 7, comments: 'A1 reviewing A2')
      create_scored_response(map: teammate_map_a2, item: item, score: 8, comments: 'A2 reviewing A1')
      create_scored_response(map: teammate_map_b1, item: item, score: 6, comments: 'B1 reviewing B2')
      create_scored_response(map: teammate_map_b2, item: item, score: 9, comments: 'B2 reviewing B1')

      feedback_map_for_a1 = FeedbackResponseMap.create!(
        reviewed_object_id: poor_review_map.id,
        reviewer_id: participant_b1.id,
        reviewee_id: participant_a1.id
      )
      feedback_map_for_b1 = FeedbackResponseMap.create!(
        reviewed_object_id: good_review_map.id,
        reviewer_id: participant_a1.id,
        reviewee_id: participant_b1.id
      )

      create_scored_response(map: feedback_map_for_a1, item: item, score: 3, comments: 'Feedback for Team One reviewer')
      create_scored_response(map: feedback_map_for_b1, item: item, score: 8, comments: 'Feedback for Team Two reviewer')

      export_payload = Export.perform(Grades)
      csv_text = export_payload.first[:contents]

      puts "\nGrades export CSV:"
      puts csv_text

      rows = CSV.parse(csv_text, headers: true)

      expect(rows.headers).to eq(Grades::COLUMN_NAMES)
      expect(rows.size).to eq(4)

      row_by_participant = rows.index_by { |row| row['participant_name'] }

      expect(row_by_participant.keys).to contain_exactly(
        participant_a1.user_name,
        participant_a2.user_name,
        participant_b1.user_name,
        participant_b2.user_name
      )

      expect(row_by_participant[participant_a1.user_name]['assignment_id']).to eq(assignment.id.to_s)
      expect(row_by_participant[participant_a1.user_name]['assignment_name']).to eq(assignment.name)
      expect(row_by_participant[participant_a1.user_name]['team_name']).to eq(team_one.name)
      expect(row_by_participant[participant_a1.user_name]['participant_email']).to eq(alice.email)

      expect(row_by_participant[participant_a2.user_name]['assignment_id']).to eq(assignment.id.to_s)
      expect(row_by_participant[participant_a2.user_name]['team_name']).to eq(team_one.name)
      expect(row_by_participant[participant_a2.user_name]['participant_email']).to eq(aaron.email)

      expect(row_by_participant[participant_b1.user_name]['assignment_id']).to eq(assignment.id.to_s)
      expect(row_by_participant[participant_b1.user_name]['team_name']).to eq(team_two.name)
      expect(row_by_participant[participant_b1.user_name]['participant_email']).to eq(bella.email)

      expect(row_by_participant[participant_b2.user_name]['assignment_id']).to eq(assignment.id.to_s)
      expect(row_by_participant[participant_b2.user_name]['team_name']).to eq(team_two.name)
      expect(row_by_participant[participant_b2.user_name]['participant_email']).to eq(ben.email)

      rows.each do |row|
        expect(row['team_id']).to be_present
        expect(row['participant_id']).to be_present
        expect(row['submission_grade']).to be_present
        expect(row['review_grade']).to be_present
      end

      expect(row_by_participant[participant_a1.user_name]['author_feedback_grade']).to be_present
      expect(row_by_participant[participant_b1.user_name]['author_feedback_grade']).to be_present
      expect(row_by_participant[participant_a1.user_name]['teammate_review_grade']).to be_present
      expect(row_by_participant[participant_a2.user_name]['teammate_review_grade']).to be_present
      expect(row_by_participant[participant_b1.user_name]['teammate_review_grade']).to be_present
      expect(row_by_participant[participant_b2.user_name]['teammate_review_grade']).to be_present
    end
  end
end
