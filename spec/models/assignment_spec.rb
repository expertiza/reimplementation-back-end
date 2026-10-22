# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Assignment, type: :model do

  let(:team) {Team.new}
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', item_id: 1) }
  let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', item_id: 1) }
  
  include RolesHelper
  before(:each) { @roles = create_roles_hierarchy }
  let(:institution) { Institution.create!(name: "NC State") } # All users belong to the same institution to satisfy foreign key constraints.
  let(:instructor) { User.create!(name: "instructor", full_name: "Instructor User", email: "instructor@example.com", password_digest: "password", role_id: @roles[:instructor].id, institution_id: institution.id) }

  # -----------------------------------------------------------------------
  # Virtual attributes (attr_writer only — no DB column)
  # -----------------------------------------------------------------------
  describe 'virtual attr_writer fields' do
    it 'apply_late_policy is settable but is not persisted to the DB' do
      a = Assignment.create!(name: 'Virtual Late', instructor: instructor)
      a.apply_late_policy = true
      a.save!
      expect(a.reload.is_penalty_calculated).to be_falsy
    end

    it 'has_max_review_limit is settable but is not persisted to the DB' do
      a = Assignment.create!(name: 'Virtual Max', instructor: instructor,
                             num_reviews_allowed: 0)
      a.has_max_review_limit = true
      a.save!
      expect(a.reload.num_reviews_allowed).to eq(0)
    end
  end

  # -----------------------------------------------------------------------
  # is_penalty_calculated — real DB boolean
  # -----------------------------------------------------------------------
  describe '#is_penalty_calculated' do
    it 'defaults to false' do
      a = Assignment.create!(name: 'Default Penalty', instructor: instructor)
      expect(a.is_penalty_calculated).to be_falsy
    end

    it 'persists true when set on save' do
      a = Assignment.create!(name: 'Penalty True', instructor: instructor,
                             is_penalty_calculated: true)
      expect(a.reload.is_penalty_calculated).to be true
    end

    it 'can be toggled off after being set' do
      a = Assignment.create!(name: 'Toggle Penalty', instructor: instructor,
                             is_penalty_calculated: true)
      a.update!(is_penalty_calculated: false)
      expect(a.reload.is_penalty_calculated).to be false
    end
  end

  # -----------------------------------------------------------------------
  # set_allowed_number_of_reviews_per_reviewer alias (→ num_reviews_allowed)
  # -----------------------------------------------------------------------
  describe '#set_allowed_number_of_reviews_per_reviewer' do
    it 'reads and writes through the num_reviews_allowed DB column' do
      a = Assignment.create!(name: 'Review Limit Model', instructor: instructor,
                             num_reviews_allowed: 3)
      expect(a.set_allowed_number_of_reviews_per_reviewer).to eq(3)
    end

    it 'persists when updated via the alias' do
      a = Assignment.create!(name: 'Review Limit Update', instructor: instructor,
                             num_reviews_allowed: 0)
      a.update!(set_allowed_number_of_reviews_per_reviewer: 7)
      expect(a.reload.num_reviews_allowed).to eq(7)
    end
  end

  # -----------------------------------------------------------------------
  # Named due_dates — dropdown updates without changing due_at
  # -----------------------------------------------------------------------
  describe 'updating named deadline dropdowns without changing due_at' do
    it 'preserves due_at when updating only the allowed_id columns' do
      a = Assignment.create!(name: 'Dropdown Only', instructor: instructor)
      original_due_at = 3.days.from_now
      dd = AssignmentDueDate.create!(
        parent: a,
        due_at: original_due_at,
        deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
        submission_allowed_id: 3, review_allowed_id: 3, teammate_review_allowed_id: 3
      )

      # Update only the allowed_ids — no due_at in the nested attributes
      a.update!(due_dates_attributes: [{
        id: dd.id,
        deadline_type_id: ExpertizaConstants::DeadlineTypes::DROP_TOPIC,
        submission_allowed_id: 1,
        review_allowed_id: 2,
        teammate_review_allowed_id: 1
      }])

      dd.reload
      expect(dd.due_at.to_i).to be_within(1).of(original_due_at.to_i)
      expect(dd.submission_allowed_id).to eq(1)
      expect(dd.review_allowed_id).to eq(2)
    end
  end

  describe '#num_review_rounds' do
    it 'counts review due dates to determine the number of rounds' do
      assignment = Assignment.create!(name: 'Round Count', instructor: instructor, vary_by_round: true)
      AssignmentDueDate.create!(parent: assignment, due_at: 1.day.from_now,
                                deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
                                submission_allowed_id: 3, review_allowed_id: 3)
      AssignmentDueDate.create!(parent: assignment, due_at: 2.days.from_now,
                                deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
                                submission_allowed_id: 3, review_allowed_id: 3)

      expect(assignment.num_review_rounds).to eq(2)
    end

    it 'ignores non-review deadlines when counting rounds' do
      assignment = Assignment.create!(name: 'Mixed Deadlines', instructor: instructor, vary_by_round: true)
      AssignmentDueDate.create!(parent: assignment, due_at: 1.day.from_now,
                                deadline_type_id: 99,
                                submission_allowed_id: 3, review_allowed_id: 3)
      AssignmentDueDate.create!(parent: assignment, due_at: 2.days.from_now,
                                deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
                                submission_allowed_id: 3, review_allowed_id: 3)

      expect(assignment.num_review_rounds).to eq(1)
    end
  end

  describe '#varying_rubrics_by_round?' do
    let(:questionnaire) { Questionnaire.create!(name: 'Review Q', instructor_id: instructor.id, questionnaire_type: 'ReviewQuestionnaire',
                                                display_type: 'Review', min_question_score: 0, max_question_score: 5) }

    it 'returns false when vary_by_round is disabled even if rounds exist' do
      assignment = Assignment.create!(name: 'No Vary', instructor: instructor, vary_by_round: false)
      AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1)

      expect(assignment.varying_rubrics_by_round?).to be false
    end

    it 'returns true when vary_by_round is enabled and a round-specific rubric exists' do
      assignment = Assignment.create!(name: 'Vary', instructor: instructor, vary_by_round: true)
      AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1)

      expect(assignment.varying_rubrics_by_round?).to be true
    end
  end

  describe '.get_all_review_comments' do
    it 'returns concatenated review comments and # of reviews in each round' do
      allow(Assignment).to receive(:find).with(1).and_return(assignment)
      allow(assignment).to receive(:num_review_rounds).and_return(3)
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:responses).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer])
      allow(response2).to receive(:scores).and_return([answer2])
      expect(assignment.get_all_review_comments(1)).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  # Get a collection of all comments across all rounds of a review as well as a count of the total number of comments. Returns the above
  # information both for totals and in a list per-round.
  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(assignment).to receive(:get_all_review_comments).with(1)
                                                                  .and_return([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
      expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
    end
  end
end