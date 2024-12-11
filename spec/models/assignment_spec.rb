
require 'rails_helper'

RSpec.describe Assignment, type: :model do
  let(:instructor) { create(:user) }
  let(:course) { create(:course) }
  let(:assignment) {
    Assignment.create(
      name: 'Test Assignment',
      directory_path: '/path/to/assignment',
      course_id: course.id,
      instructor_id: instructor.id,
      require_quiz: true,
      num_quiz_questions: 5,
      description: 'Assignment Description'
    )
  }

  describe 'Model associations and validations' do
    it 'belongs to course' do
      expect(assignment).to belong_to(:course)
    end

    it 'belongs to instructor' do
      expect(assignment).to belong_to(:instructor)
    end

    it 'validates presence of name' do
      expect(assignment).to validate_presence_of(:name)
    end

    it 'validates presence of directory_path' do
      expect(assignment).to validate_presence_of(:directory_path)
    end

    it 'validates presence of require_quiz' do
      expect(assignment.require_quiz).to be true
    end

    it 'validates numericality of num_quiz_questions' do
      expect(assignment).to validate_numericality_of(:num_quiz_questions).is_greater_than_or_equal_to(0)
    end

    it 'has a valid factory' do
      expect(assignment).to be_valid
    end
  end

  describe '.get_all_review_comments' do
    let(:team) { Team.new }
    let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
    let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
    let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }

    it 'returns concatenated review comments and # of reviews in each round' do
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: assignment.id)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:response).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer])
      allow(response2).to receive(:scores).and_return([answer2])

      result = assignment.get_all_review_comments(1)
      expect(result).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(assignment).to receive(:get_all_review_comments).with(1)
                                                            .and_return([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
      expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
    end
  end
end
