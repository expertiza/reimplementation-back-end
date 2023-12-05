require 'rails_helper'
RSpec.describe Assignment, type: :model do

  # let(:team) {Team.new}
  # let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  # let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  # let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  # let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }

  # describe '.get_all_review_comments' do
  #   it 'returns concatenated review comments and # of reviews in each round' do
  #     allow(Assignment).to receive(:find).with(1).and_return(assignment)
  #     allow(assignment).to receive(:num_review_rounds).and_return(2)
  #     allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
  #                                                                          .with(no_args).and_yield(review_response_map)
  #     response1 = double('Response', round: 1, additional_comment: '')
  #     response2 = double('Response', round: 2, additional_comment: 'LGTM')
  #     allow(review_response_map).to receive(:response).and_return([response1, response2])
  #     allow(response1).to receive(:scores).and_return([answer])
  #     allow(response2).to receive(:scores).and_return([answer2])
  #     expect(assignment.get_all_review_comments(1)).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
  #   end
  # end
  #
  # # Get a collection of all comments across all rounds of a review as well as a count of the total number of comments. Returns the above
  # # information both for totals and in a list per-round.
  # describe '.volume_of_review_comments' do
  #   it 'returns volumes of review comments in each round' do
  #     allow(assignment).to receive(:get_all_review_comments).with(1)
  #                                                                 .and_return([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
  #     expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
  #   end
  # end

  describe '.add_participant' do
    let(:user) {
      create(:user)
    }
    let(:assignment) { create(:assignment) }


    it 'adds the user as a participant' do
      expect do
        assignment.add_participant(user.id)
      end.to change(AssignmentParticipant, :count).by(1)

      new_participant = AssignmentParticipant.last
      expect(new_participant.assignment).to eq(assignment)
      expect(new_participant.user).to eq(user)
    end



    it 'raises an error and does not add a participant' do
      non_existing_user_id = nil # Assuming this ID does not exist
      expect do
        expect do
          assignment.add_participant(non_existing_user_id)
        end.to raise_error(RuntimeError, /The user account does not exist/)
      end.not_to change(AssignmentParticipant, :count)
    end


    it 'raises an error and does not add a duplicate participant' do
      assignment.add_participant(user.id) # Adding the user as a participant
      expect do
        expect do
          assignment.add_participant(user.id)
        end.to raise_error(RuntimeError, /The user .* is already a participant/)
      end.not_to change(AssignmentParticipant, :count)
    end
    
  end

  describe '#remove_participant' do
    let(:assignment) { create(:assignment) }
    let(:user) { create(:user) }

    it 'removes the participant with the specified user_id' do
      # Add the user as a participant first
      assignment.add_participant(user.id)
      expect do
        assignment.remove_participant(user.id)
      end.to change(AssignmentParticipant, :count).by(-1)

      # Ensure that the participant is removed from the assignment
      expect(AssignmentParticipant.where(user_id: user.id)).to be_empty
    end

    it 'does not remove a non-participant' do
      non_participant = create(:user) # Create a user who is not a participant

      expect do
        assignment.remove_participant(non_participant.id)
      end.not_to change(AssignmentParticipant, :count)
    end
  end

  describe '.assign_courses_to_assignment' do
    let(:assignment) {create(:assignment)}  # Create a new Assignment using the factory
    let(:course) {create(:course)}
    it 'assigns a course to an assignment' do
      updated_assignment = assignment.assign_courses_to_assignment(course.id)
      expect(updated_assignment.course_id).to eq(course.id)
    end

    it 'raises an error if the assignment already belongs to the course' do
      assignment.course_id = course.id
      assignment.save

      expect { assignment.assign_courses_to_assignment(course.id) }
        .to raise_error("The assignment already belongs to this course id.")
    end
  end
  
  describe '#remove_assignment_from_course' do
    let(:assignment) {create(:assignment)}  # Create a new Assignment using the factory
    let(:course) {create(:course)}
    it 'sets course_id to nil' do

      assignment.course_id = course.id
      # Call the method to remove the course
      modified_assignment = assignment.remove_assignment_from_course

      # Verify that the course_id is set to nil
      expect(modified_assignment.course_id).to be_nil
    end

    it 'raises an error if the assignment does not belongs to any course' do
      
      expect { assignment.remove_assignment_from_course }
        .to raise_error("The assignment does not belong to any course.")
    end
  end

  describe '#copy_assignment' do
    # Create an assignment using FactoryBot
    let(:assignment) {create(:assignment)}
    it 'creates a copy of the assignment with a new name' do
      # Call the copy_assignment method on the original assignment
      copied_assignment = assignment.copy_assignment

      # Expectations
      expect(copied_assignment).to be_an_instance_of(Assignment)
      expect(copied_assignment.name).to eq('Copy of ' + assignment.name)
      expect(copied_assignment.course).to eq(assignment.course)
      expect(copied_assignment.instructor).to eq(assignment.instructor)
    end
  end
  describe '#is_calibrated?' do
    let(:assignment) { create(:assignment) }

    context 'when is_calibrated is true' do
      it 'returns true' do
        assignment.is_calibrated = true
        expect(assignment.is_calibrated?).to be true
      end
    end

    context 'when is_calibrated is false' do
      it 'returns false' do
        assignment.is_calibrated = false
        expect(assignment.is_calibrated?).to be false
      end
    end
  end
  describe '#has_badge?' do
    let(:assignment) { Assignment.new }

    context 'when has_badge is true' do
      it 'returns true' do
        assignment.has_badge = true
        expect(assignment.has_badge?).to be true
      end
    end

    context 'when has_badge is false' do
      it 'returns false' do
        assignment.has_badge = false
        expect(assignment.has_badge?).to be false
      end
    end
  end
  describe '#valid_num_review' do
    let(:assignment) { Assignment.new }

    context 'when review_type is "review"' do
      it 'returns success: true if num_reviews_required is less than or equal to num_reviews_allowed' do
        assignment.num_reviews_required = 2
        assignment.num_reviews_allowed = 5

        result = assignment.valid_num_review('review')

        expect(result[:success]).to be true
        expect(result[:message]).to be_nil
      end

      it 'returns an error message if num_reviews_required is greater than num_reviews_allowed' do
        assignment.num_reviews_required = 5
        assignment.num_reviews_allowed = 2

        result = assignment.valid_num_review('review')

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Number of reviews required cannot be greater than number of reviews allowed')
      end
    end

    context 'when review_type is "metareview"' do
      it 'returns success: true if num_metareviews_required is less than or equal to num_metareviews_allowed' do
        assignment.num_metareviews_required = 2
        assignment.num_metareviews_allowed = 5

        result = assignment.valid_num_review('metareview')

        expect(result[:success]).to be true
        expect(result[:message]).to be_nil
      end

      it 'returns an error message if num_metareviews_required is greater than num_metareviews_allowed' do
        assignment.num_metareviews_required = 5
        assignment.num_metareviews_allowed = 2

        result = assignment.valid_num_review('metareview')

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Number of metareviews required cannot be greater than number of reviews allowed')
      end
    end
  end
  describe '#teams?' do
    let(:assignment) {create(:assignment)}

    context 'when teams are associated with the assignment' do
      it 'returns true' do
        # Create a team associated with the assignment using FactoryBot
        team = create(:team, assignment: assignment)

        expect(assignment.teams?).to be true
      end
    end

    context 'when no teams are associated with the assignment' do
      it 'returns false' do

        expect(assignment.teams?).to be false
      end
    end
  end

  describe '#topics?' do
    let(:assignment) { create(:assignment) }

    context 'when sign_up_topics is empty' do
      it 'returns false' do
        # Assuming sign_up_topics is an empty collection

        expect(assignment.topics?).to be false
      end
    end

    context 'when sign_up_topics is not empty' do
      it 'returns true' do
        # Assuming sign_up_topics is a non-empty collection
        sign_up_topic = create(:sign_up_topic, assignment: assignment)
        expect(assignment.topics?).to be true
      end
    end
  end

  describe '#varying_rubrics_by_round?' do
    let(:assignment) { create(:assignment) }
    let(:questionnaire) {create(:questionnaire)}
    context 'when rubrics with specified rounds are present' do
      it 'returns true' do
        # Assuming rubrics with specified rounds exist for the assignment
        create(:assignment_questionnaire, assignment: assignment, questionnaire: questionnaire, used_in_round: 1)

        expect(assignment.varying_rubrics_by_round?).to be true
      end
    end

    context 'when no rubrics with specified rounds are present' do
      it 'returns false' do
        # Assuming no rubrics with specified rounds exist for the assignment
        expect(assignment.varying_rubrics_by_round?).to be false
      end
    end
  end

  describe "pair_programming_enabled?" do
    let(:assignment) {create(:assignment)}
    context "when pair programming is enabled" do
      before do
        # Enable pair programming before each test in this context
        assignment.enable_pair_programming = true
      end

      it "returns true" do
        expect(assignment.pair_programming_enabled?).to eq(true)
      end
    end

    context "when pair programming is disabled" do
      before do
        # Disable pair programming before each test in this context
        assignment.enable_pair_programming=false
        # You may need a method to disable pair programming if it's not the inverse of enable_pair_programming
      end

      it "returns false" do
        expect(assignment.pair_programming_enabled?).to eq(false)
      end
    end
  end


  describe "staggered_and_no_topic?" do
    let(:assignment) {create(:assignment)}
    context "when staggered deadline is enabled and topic_id is not provided" do
      it "returns true" do
        allow(assignment).to receive(:staggered_deadline?).and_return(true)
        expect(assignment.staggered_and_no_topic?(nil)).to eq(true)
      end
    end

    context "when staggered deadline is enabled and topic_id is provided" do
      it "returns false" do
        allow(assignment).to receive(:staggered_deadline?).and_return(true)
        expect(assignment.staggered_and_no_topic?("some_topic_id")).to eq(false)
      end
    end

    context "when staggered deadline is disabled and topic_id is not provided" do
      it "returns false" do
        allow(subject).to receive(:staggered_deadline?).and_return(false)
        expect(assignment.staggered_and_no_topic?(nil)).to eq(false)
      end
    end

    context "when staggered deadline is disabled and topic_id is provided" do
      it "returns false" do
        allow(assignment).to receive(:staggered_deadline?).and_return(false)
        expect(assignment.staggered_and_no_topic?("some_topic_id")).to eq(false)
      end
    end
  end


  describe "#create_node" do
    let(:assignment) { create(:assignment) }

    context "when the parent node exists" do
      it "creates a new assignment node with the given id, sets parent_id, and saves the new node" do
        # Stub CourseNode.find_by to return a mock parent node
        allow(CourseNode).to receive(:find_by).and_return(double("CourseNode", id: 10))

        # Expectations for AssignmentNode creation
        expect(AssignmentNode).to receive(:create).with(node_object_id: assignment.id).and_call_original

        # Expectations for any_instance of AssignmentNode
        assignment_node_instance = instance_double(AssignmentNode)
        allow(assignment_node_instance).to receive(:parent_id=)
        allow(assignment_node_instance).to receive(:save)

        expect(AssignmentNode).to receive(:new).and_return(assignment_node_instance)

        # Call the method under test
        assignment.create_node
      end
    end

    context "when the parent node does not exist" do
      it "creates a new assignment node with the given id, does not set parent_id, and saves the new node" do
        # Stub CourseNode.find_by to return nil (no parent node)
        allow(CourseNode).to receive(:find_by).and_return(nil)

        # Expectations for AssignmentNode creation
        expect(AssignmentNode).to receive(:create).with(node_object_id: assignment.id).and_call_original

        # Expectations for any_instance of AssignmentNode
        assignment_node_instance = instance_double(AssignmentNode)
        expect(assignment_node_instance).not_to receive(:parent_id=)
        allow(assignment_node_instance).to receive(:save)

        expect(AssignmentNode).to receive(:new).and_return(assignment_node_instance)

        # Call the method under test
        assignment.create_node
      end
    end
  end


  describe 'team_assignment?' do
    let(:assignment) { create(:assignment) }
    context 'when max_team_size is greater than 1' do
      it 'returns true' do
        assignment.max_team_size = 5
        expect(assignment.team_assignment?).to be true
      end
    end

    context 'when max_team_size is equal to 1' do
      it 'returns false' do
        assignment.max_team_size = 1
        expect(assignment.team_assignment?).to be false
      end
    end

    context "when max_team_size is nil" do
      it "returns false" do
        expect(assignment.team_assignment?).to be false
      end
    end
  end






end
