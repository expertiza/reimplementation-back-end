# frozen_string_literal: true
require 'rails_helper'

##just needs to validate that submission is valid, if anything

RSpec.describe SubmissionRecord, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      submission = build(:submission_record)
      expect(submission).to be_valid
    end

    it "is invalid without a user" do
      submission = build(:submission_record, user: nil)
      expect(submission).not_to be_valid
    end

    it "is invalid without an assignment" do
      submission = build(:submission_record, assignment: nil)
      expect(submission).not_to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:assignment) }
  end

  describe "scopes and methods" do
    let(:user) { create(:user) }
    let(:assignment) { create(:assignment) }
    let!(:old_submission) { create(:submission_record, user: user, assignment: assignment, created_at: 1.week.ago) }
    let!(:new_submission) { create(:submission_record, user: user, assignment: assignment, created_at: 1.day.ago) }

    it "returns submissions in descending order" do
      expect(SubmissionRecord.ordered_by_date).to eq([new_submission, old_submission])
    end
  end
end

