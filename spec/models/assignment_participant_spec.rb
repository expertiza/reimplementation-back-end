require "rails_helper"

describe 'AssignmentParticipant' do
    let(:response) { build(:response) }
    let(:team) { build(:assignment_team, id: 1) }
    let(:team2) { build(:assignment_team, id: 2) }
    let(:response_map) { build(:review_response_map, reviewer_id: 2, response: [response]) }
    let(:participant) { build(:participant, id: 1, assignment: assignment) }
    let(:participant2) { build(:participant, id: 2, grade: 100) }
    let(:assignment) { build(:assignment, id: 1) }
    #let(:review_questionnaire) { build(:questionnaire, id: 1) }
    let(:question) { double('Question') }
    # before(:each) do
    #   allow(assignment).to receive(:questionnaires).and_return([review_questionnaire])
    #   allow(participant).to receive(:team).and_return(team)
    # end


    #This test case has passed
    describe '#dir_path' do
      it 'returns the directory path of current assignment' do
        expect(participant.dir_path).to eq('final_test')
      end
    end
    #to be discussed with Devashish
    # Pass Failed
    describe '#reviewers' do
      it 'returns all the participants in this assignment who have reviewed the team where this participant belongs' do
        allow(ReviewResponseMap).to receive(:where).with('reviewee_id = ?', 1).and_return([response_map])
        allow(AssignmentParticipant).to receive(:find).with(2).and_return(participant2)
        expect(participant.reviewers).to eq([participant2])
      end
    end
    # to be discussed with Devashish
    # Pass Failed
    describe '#get_reviewer' do
      context 'when the associated assignment is reviewed by his team' do
        it 'returns the team' do
          allow(assignment).to receive(:team_reviewing_enabled).and_return(true)
          allow(participant).to receive(:team).and_return(team)
          expect(participant.get_reviewer).to eq(team)
        end
      end
    end


    #This Test Cases has passed
    describe '#path' do
      it 'returns the path name of the associated assignment submission for the team' do
        allow(assignment).to receive(:path).and_return('assignment780')
        allow(participant).to receive(:team).and_return(team)
        allow(team).to receive(:directory_num).and_return(780)
        expect(participant.path).to eq('assignment780/780')
      end
    end
    # discuss with Devashish
    describe '#copy_to_course' do
      it 'copies assignment participants to a certain course' do
        # Stubbing CourseParticipant.find_or_create_by method
        allow(CourseParticipant).to receive(:find_or_create_by).and_return(CourseParticipant.new(user_id: 2, parent_id: 123))

        expect { participant.copy_to_course(123) }.to change { CourseParticipant.count }.by(1)
        expect(CourseParticipant.first.user_id).to eq(2)
        expect(CourseParticipant.first.parent_id).to eq(123)
      end
    end

    #This Test case have passed
    describe '#feedback' do
      it 'returns corresponding author feedback responses given by current participant' do
        allow(FeedbackResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        expect(participant.feedback).to eq([response])
      end
    end
    #This Test Case have passed
    describe '#reviews' do
      it 'returns corresponding peer review responses given by current team' do
        # Ensure the participant is associated with the team
        allow(participant).to receive(:team).and_return(team)
        allow(ReviewResponseMap).to receive(:assessments_for).with(team).and_return([response])
        expect(participant.reviews).to eq([response])
      end
    end
    #This Test Case has passed
    describe '#quizzes_taken' do
      it 'returns corresponding quiz responses given by current participant' do
        allow(QuizResponseMap).to receive(:assessments_for).with(participant).and_return([response])
        expect(participant.quizzes_taken).to eq([response])
      end
    end


    # describe "#average_question_score" do
    #
    #   context "when there are response maps for the question" do
    #
    #     end
    #
    #     it "calculates the average score for the question correctly" do
    #
    #     end
    #
    #     it "rounds the average score to two decimal places" do
    #
    #     end
    #   end
    #
    #   context "when there are no response maps for the question" do
    #     it "returns nil for a question without response maps" do
    #
    #     end
    #
    #     it "returns nil regardless of the question" do
    #
    #     end
    #
    #     it "always returns nil for any question without response maps" do
    #
    #     end
    #   end

    # describe "#dir_path" do
#   before(:each) do
#     @assignment = create(:assignment)
#   end
#   context "when assignment has a directory path" do
#     it "returns the directory path of the assignment" do
#       # Create a test double for the assignment with a directory path.
#       assignment = double("assignment", directory_path: "final_test")
#       # Set the expectation that the directory_path method should return the path.
#       expect(assignment).to receive(:directory_path).and_return("final_test")
#       # Call the dir_path method and expect it to return the path.
#       result = dir_path(assignment)
#       expect(result).to eq("final_test")
#     end
#   end

  # context "when assignment does not have a directory path" do
  #   it "returns nil" do
  #     # Create a test double for the assignment with no directory path.
  #     assignment = double("assignment", directory_path: nil)
  #     # Set the expectation that the directory_path method should return nil.
  #     expect(assignment).to receive(:directory_path).and_return(nil)
  #     # Call the dir_path method and expect it to return nil.
  #     result = dir_path(assignment)
  #     expect(result).to be_nil
  #   end
  # end
    #end
# describe "#average_score" do
#   context "when there are no response maps" do
#     it "returns 0" do
#       # test body
#     end
#   end
#
#   context "when there are response maps" do
#     it "calculates the average score correctly" do
#       # test body
#     end
#   end
#
#   context "when some response maps have empty responses" do
#     it "ignores those response maps in the calculation" do
#       # test body
#     end
#   end
# end
# describe "#includes?" do
#   context "when the participant is included in the list" do
#     it "returns true" do
#       # Test body
#     end
#   end
#
#   context "when the participant is not included in the list" do
#     it "returns false" do
#       # Test body
#     end
#   end
#
#   context "when the participant is an empty string" do
#     it "returns false" do
#       # Test body
#     end
#   end
#
#   context "when the participant is nil" do
#     it "returns false" do
#       # Test body
#     end
#   end
# end
# describe "assign_reviewer" do
#   context "when a reviewer is assigned to a team" do
#     it "creates a review response map with the correct parameters" do
#       # Test code here
#     end
#   end
# end
# describe "assign_quiz" do
#   context "when given a contributor, reviewer, and topic" do
#     it "should assign a quiz to the contributor for review" do
#       # Test scenario 1
#       # Given a contributor, reviewer, and topic
#       # When the assign_quiz method is called
#       # Then a quiz should be assigned to the contributor for review
#
#       # Test scenario 2
#       # Given a contributor, reviewer, and topic
#       # When the assign_quiz method is called
#       # Then a quiz should be created and associated with the contributor
#
#       # Test scenario 3
#       # Given a contributor, reviewer, and topic
#       # When the assign_quiz method is called
#       # Then a quiz response map should be created with the appropriate reviewer and reviewee
#
#       # Test scenario 4
#       # Given a contributor, reviewer, and topic
#       # When the assign_quiz method is called
#       # Then the quiz response map should have the correct type
#
#       # Test scenario 5
#       # Given a contributor, reviewer, and topic
#       # When the assign_quiz method is called
#       # Then the quiz response map should have the correct reviewed object ID
#     end
#   end
# end
# describe AssignmentParticipant do
#   describe ".find_by_user_id_and_assignment_id" do
#     context "when a matching assignment participant exists" do
#       it "returns the assignment participant with the given user_id and assignment_id"
#     end
#
#     context "when no matching assignment participant exists" do
#       it "returns nil"
#     end
#   end
# end
# describe "has_submissions?" do
#   context "when the team has submitted files" do
#     it "returns true" do
#       # Test scenario 1
#     end
#   end
#
#   context "when the team has not submitted any files" do
#     context "and there are hyperlinks" do
#       it "returns true" do
#         # Test scenario 2
#       end
#     end
#
#     context "and there are no hyperlinks" do
#       it "returns false" do
#         # Test scenario 3
#       end
#     end
#   end
# end
# describe "#reviewers" do
#   context "when there are review response maps for the team" do
#     it "returns an array of assignment participants who are reviewers" do
#       # Test scenario 1
#       # Given a team with review response maps
#       # When the method is called
#       # Then it should return an array of assignment participants who are reviewers
#
#       # Test scenario 2
#       # Given a team without any review response maps
#       # When the method is called
#       # Then it should return an empty array
#     end
#   end
# end
# describe "#review_score" do
#   context "when there are no assessments for the review questionnaire" do
#     it "returns 0" do
#       # test code
#     end
#   end
#
#   context "when there is one assessment for the review questionnaire" do
#     it "returns the computed score for the assessment" do
#       # test code
#     end
#   end
#
#   context "when there are multiple assessments for the review questionnaire" do
#     it "returns the average computed score for all assessments" do
#       # test code
#     end
#   end
#
#   context "when the review questionnaire has a maximum possible score of 100" do
#     it "returns the computed score as a percentage of the maximum possible score" do
#       # test code
#     end
#   end
#
#   context "when the review questionnaire has a maximum possible score other than 100" do
#     it "returns the computed score as a percentage of the maximum possible score" do
#       # test code
#     end
#   end
# end
# describe "#fullname" do
#   context "when user has a fullname" do
#     it "returns the fullname of the user" do
#       # Test body
#     end
#   end
#
#   context "when user does not have a fullname" do
#     it "returns nil" do
#       # Test body
#     end
#   end
# end
# describe "#name" do
#   context "when user is present" do
#     it "returns the name of the user" do
#       # Test body
#     end
#   end
#
#   context "when user is not present" do
#     it "returns nil" do
#       # Test body
#     end
#   end
# end
# describe "#scores" do
#   context "when called on a participant" do
#     it "returns a hash of scores" do
#       # test code
#     end
#   end
#
#   context "when the participant has completed questionnaires" do
#     it "calculates scores for each questionnaire" do
#       # test code
#     end
#   end
#
#   context "when the participant has completed quiz questionnaires" do
#     it "calculates scores for quiz questionnaires" do
#       # test code
#     end
#   end
#
#   context "when the assignment is a microtask" do
#     it "scales the total score and records the maximum points available" do
#       # test code
#     end
#   end
#
#   context "when the participant has a grade" do
#     it "returns the grade as the total score" do
#       # test code
#     end
#   end
#
#   context "when the total score exceeds 100" do
#     it "limits the total score to 100" do
#       # test code
#     end
#   end
# end
# describe "#submit_hyperlink" do
#   context "when the hyperlink is valid" do
#     it "strips leading and trailing whitespace from the hyperlink" do
#       # test body
#     end
#
#     it "adds the hyperlink to the hyperlinks_array" do
#       # test body
#     end
#
#     it "updates the submitted_hyperlinks attribute of the team object" do
#       # test body
#     end
#
#     it "saves the team object" do
#       # test body
#     end
#   end
#
#   context "when the hyperlink is empty" do
#     it "raises an exception with the message 'The hyperlink cannot be empty'" do
#       # test body
#     end
#   end
#
#   context "when the hyperlink is not a valid URL" do
#     it "raises an exception" do
#       # test body
#     end
#   end
# end
# describe "remove_hyperlink" do
#   context "when a hyperlink exists in the hyperlinks_array" do
#     it "removes the specified hyperlink from the hyperlinks_array" do
#       # Test code here
#     end
#
#     it "updates the submitted_hyperlinks attribute of the team object" do
#       # Test code here
#     end
#
#     it "saves the updated team object" do
#       # Test code here
#     end
#   end
#
#   context "when the specified hyperlink does not exist in the hyperlinks_array" do
#     it "does not modify the hyperlinks_array" do
#       # Test code here
#     end
#
#     it "does not update the submitted_hyperlinks attribute of the team object" do
#       # Test code here
#     end
#
#     it "does not save the team object" do
#       # Test code here
#     end
#   end
# end
# describe "#hyperlinks" do
#   context "when team has hyperlinks" do
#     it "returns an array of hyperlinks" do
#       # Test body
#     end
#   end
#
#   context "when team does not have hyperlinks" do
#     it "returns an empty array" do
#       # Test body
#     end
#   end
# end
# describe "#hyperlinks_array" do
#   context "when team's submitted_hyperlinks is blank" do
#     it "returns an empty array" do
#       # test body
#     end
#   end
#
#   context "when team's submitted_hyperlinks is not blank" do
#     it "returns an array of hyperlinks" do
#       # test body
#     end
#   end
# end
# describe "#copy" do
#   context "when the user is not already a participant in the course" do
#     it "creates a new CourseParticipant record for the user and the specified course" do
#       # Test scenario code here
#     end
#   end
#
#   context "when the user is already a participant in the course" do
#     it "does not create a new CourseParticipant record" do
#       # Test scenario code here
#     end
#   end
# end
# describe Feedback do
#   describe "#feedback" do
#     context "when called" do
#       it "returns a list of assessments for the given object" do
#         # Test body not included
#       end
#     end
#   end
# end
# describe "#reviews" do
#   context "when called on a team" do
#     it "returns assessments for the team" do
#       # Test scenario 1
#       # Given a team
#       # When #reviews is called on the team
#       # Then it should return the assessments for the team
#
#       # Test scenario 2
#       # Given a team with no assessments
#       # When #reviews is called on the team
#       # Then it should return an empty array
#
#       # Test scenario 3
#       # Given a team with multiple assessments
#       # When #reviews is called on the team
#       # Then it should return an array containing all the assessments for the team
#     end
#   end
# end
# describe "#reviews_by_reviewer" do
#   context "when there are assessments by the reviewer" do
#     it "returns the assessments made by the specified reviewer for the team" do
#       # Test scenario 1
#       # Given a team and a reviewer
#       # When there are assessments made by the reviewer for the team
#       # Then the method should return the assessments made by the reviewer
#
#       # Test scenario 2
#       # Given a team and a different reviewer
#       # When there are assessments made by the different reviewer for the team
#       # Then the method should return the assessments made by the different reviewer
#
#       # Test scenario 3
#       # Given a team and a reviewer
#       # When there are no assessments made by the reviewer for the team
#       # Then the method should return an empty array
#     end
#   end
#
#   context "when there are no assessments by the reviewer" do
#     it "returns an empty array" do
#       # Test scenario 4
#       # Given a team and a reviewer
#       # When there are no assessments made by the reviewer for the team
#       # Then the method should return an empty array
#     end
#   end
# end
# describe "#quizzes_taken" do
#   context "when there are assessments for the user" do
#     it "returns an array of assessments taken by the user" do
#       # Test scenario 1
#       # Given a user with assessments
#       # When the method quizzes_taken is called
#       # Then it should return an array of assessments taken by the user
#
#       # Test scenario 2
#       # Given a user with multiple assessments
#       # When the method quizzes_taken is called
#       # Then it should return an array containing all the assessments taken by the user
#     end
#   end
#
#   context "when there are no assessments for the user" do
#     it "returns an empty array" do
#       # Test scenario 1
#       # Given a user with no assessments
#       # When the method quizzes_taken is called
#       # Then it should return an empty array
#
#       # Test scenario 2
#       # Given a user with no assessments
#       # When the method quizzes_taken is called
#       # Then it should still return an empty array
#     end
#   end
# end
# describe Metareviews do
#   describe "#metareviews" do
#     it "returns assessments for the given object" do
#       # Test scenario 1
#       # When MetareviewResponseMap.get_assessments_for is called with a valid object
#       # Then it should return the assessments associated with that object
#
#       # Test scenario 2
#       # When MetareviewResponseMap.get_assessments_for is called with an invalid object
#       # Then it should return an empty array
#
#       # Test scenario 3
#       # When MetareviewResponseMap.get_assessments_for is called with a nil object
#       # Then it should raise an error
#
#       # Test scenario 4
#       # When MetareviewResponseMap.get_assessments_for is called with a non-existent object
#       # Then it should return an empty array
#
#       # Test scenario 5
#       # When MetareviewResponseMap.get_assessments_for is called with a valid object that has no assessments
#       # Then it should return an empty array
#     end
#   end
# end
# describe "#teammate_reviews" do
#   context "when there are assessments for the teammate" do
#     it "returns a list of assessments for the teammate" do
#       # Test body not included
#     end
#   end
#
#   context "when there are no assessments for the teammate" do
#     it "returns an empty list" do
#       # Test body not included
#     end
#   end
# end
# describe "bookmark_reviews" do
#   context "when there are assessments for the bookmark" do
#     it "returns the assessments for the bookmark" do
#       # Test scenario 1
#       # Given a bookmark with assessments
#       # When bookmark_reviews is called
#       # Then it should return the assessments for the bookmark
#
#       # Test scenario 2
#       # Given a bookmark with multiple assessments
#       # When bookmark_reviews is called
#       # Then it should return all the assessments for the bookmark
#
#       # Test scenario 3
#       # Given a bookmark with no assessments
#       # When bookmark_reviews is called
#       # Then it should return an empty array
#     end
#   end
#
#   context "when there are no assessments for the bookmark" do
#     it "returns an empty array" do
#       # Test scenario 1
#       # Given a bookmark with no assessments
#       # When bookmark_reviews is called
#       # Then it should return an empty array
#
#       # Test scenario 2
#       # Given a bookmark with no assessments
#       # When bookmark_reviews is called
#       # Then it should still return an empty array
#     end
#   end
# end
# describe AssignmentTeam do
#   describe "#team" do
#     context "when called on an instance of AssignmentTeam" do
#       it "returns the team associated with the instance" do
#         # Test body not included
#       end
#     end
#   end
# end
# describe ".import" do
#   context "when user id is not specified" do
#     it "raises an ArgumentError" do
#       # Test code
#     end
#   end
#
#   context "when user is not found" do
#     it "raises an ArgumentError if the record does not have enough items" do
#       # Test code
#     end
#
#     it "creates a new user with the given attributes" do
#       # Test code
#     end
#   end
#
#   context "when assignment with the given id is not found" do
#     it "raises an ImportError" do
#       # Test code
#     end
#   end
#
#   context "when assignment participant does not exist" do
#     it "creates a new assignment participant with the user and assignment id" do
#       # Test code
#     end
#
#     it "sets a handle for the new assignment participant" do
#       # Test code
#     end
#   end
# end
# describe '.export' do
#   context 'when parent_id is valid' do
#     it 'exports user data to a CSV file' do
#       # Test setup
#
#     end
#   end
# end
# describe "export_fields" do
#   context "when options are provided" do
#     it "returns an array of field names" do
#       # Test code here
#     end
#   end
#
#   context "when options are not provided" do
#     it "returns an array of default field names" do
#       # Test code here
#     end
#   end
# end
# describe "grant_publishing_rights" do
#   context "when given a valid private key and participants" do
#     it "grants publishing rights to each participant if their digital signature is valid" do
#       # Test scenario 1
#       # Method: grant_publishing_rights
#       # Description: When given a valid private key and a list of participants, it should grant publishing rights to each participant if their digital signature is valid.
#
#       # Test scenario 2
#       # Method: grant_publishing_rights
#       # Description: When given a valid private key and an empty list of participants, it should not raise any error and return without granting publishing rights to any participant.
#
#       # Test scenario 3
#       # Method: grant_publishing_rights
#       # Description: When given an invalid private key and a list of participants, it should raise an error and not grant publishing rights to any participant.
#
#       # Test scenario 4
#       # Method: grant_publishing_rights
#       # Description: When given a valid private key and a list of participants with some invalid digital signatures, it should raise an error and not grant publishing rights to any participant.
#     end
#   end
# end
# describe "#verify_digital_signature" do
#   context "when the public key matches the private key" do
#     it "returns true" do
#       # Test scenario 1
#     end
#   end
#
#   context "when the public key does not match the private key" do
#     it "returns false" do
#       # Test scenario 2
#     end
#   end
# end
# describe "#set_handle" do
#   context "when user handle is nil or empty" do
#     it "sets handle to user's name" do
#       # Test scenario 1
#     end
#   end
#
#   context "when user handle is not nil or empty" do
#     context "when there is an existing AssignmentParticipant with the same handle" do
#       it "sets handle to user's name" do
#         # Test scenario 2
#       end
#     end
#
#     context "when there is no existing AssignmentParticipant with the same handle" do
#       it "sets handle to user's handle" do
#         # Test scenario 3
#       end
#     end
#   end
# end
# describe "#path" do
#   context "when assignment path and team directory number are present" do
#     it "returns the concatenation of assignment path and team directory number as a string" do
#       # Test body
#     end
#   end
#
#   context "when assignment path is empty and team directory number is present" do
#     it "returns the team directory number as a string" do
#       # Test body
#     end
#   end
#
#   context "when assignment path is present and team directory number is empty" do
#     it "returns the assignment path as a string" do
#       # Test body
#     end
#   end
#
#   context "when both assignment path and team directory number are empty" do
#     it "returns an empty string" do
#       # Test body
#     end
#   end
# end
# describe "review_file_path" do
#   context "when given a valid response map id" do
#     it "returns the correct file path for the response map" do
#       # Test implementation here
#     end
#   end
#
#   context "when given an invalid response map id" do
#     it "returns nil" do
#       # Test implementation here
#     end
#   end
#
#   context "when the response map has a valid reviewee and participant" do
#     it "returns the correct file path based on the assignment, team, and response map id" do
#       # Test implementation here
#     end
#   end
#
#   context "when the response map has an invalid reviewee or participant" do
#     it "returns nil" do
#       # Test implementation here
#     end
#   end
# end
# describe "#update_resubmit_times" do
#   context "when called on an instance of a class" do
#     it "creates a new ResubmissionTime object with the current timestamp" do
#       # test body
#     end
#
#     it "adds the new ResubmissionTime object to the resubmission_times array" do
#       # test body
#     end
#   end
# end
# describe "#current_stage" do
#   context "when a topic_id exists for the signed up team" do
#     it "returns the current stage of the assignment for the given topic_id" do
#       # Test scenario 1
#       # Given: A signed up team with a valid parent_id and user_id
#       # When: A topic_id is retrieved using the SignedUpTeam.topic_id method
#       # And: The assignment has a current stage for the retrieved topic_id
#       # Then: The current stage of the assignment for the topic_id is returned
#
#       # Test scenario 2
#       # Given: A signed up team with a valid parent_id and user_id
#       # When: A topic_id is retrieved using the SignedUpTeam.topic_id method
#       # And: The assignment does not have a current stage for the retrieved topic_id
#       # Then: nil is returned
#
#       # Test scenario 3
#       # Given: A signed up team with an invalid parent_id or user_id
#       # When: A topic_id is retrieved using the SignedUpTeam.topic_id method
#       # Then: nil is returned
#     end
#   end
#
#   context "when a topic_id does not exist for the signed up team" do
#     it "returns nil" do
#       # Test scenario 4
#       # Given: A signed up team with an invalid parent_id or user_id
#       # When: A topic_id is not retrieved using the SignedUpTeam.topic_id method
#       # Then: nil is returned
#     end
#   end
# end
# describe "#stage_deadline" do
#   context "when the topic_id is valid" do
#     it "calls the stage_deadline method on the assignment with the topic_id" do
#       # Test scenario 1
#     end
#   end
#
#   context "when the topic_id is invalid" do
#     it "does not call the stage_deadline method on the assignment" do
#       # Test scenario 2
#     end
#   end
# end
# describe "#review_response_maps" do
#   context "when given a valid participant id" do
#     it "returns the review response maps for the specified participant" do
#       # Test scenario 1
#       # Given a valid participant id
#       # When calling the review_response_maps method
#       # Then it should return the review response maps for the specified participant
#
#       # Test scenario 2
#       # Given a valid participant id
#       # When calling the review_response_maps method
#       # Then it should return an array of review response maps
#
#       # Test scenario 3
#       # Given a valid participant id
#       # When calling the review_response_maps method
#       # Then it should only return review response maps with the specified reviewee id
#
#       # Test scenario 4
#       # Given a valid participant id
#       # When calling the review_response_maps method
#       # Then it should only return review response maps for the specified assignment id
#     end
#   end
#
#   context "when given an invalid participant id" do
#     it "returns an empty array" do
#       # Test scenario 5
#       # Given an invalid participant id
#       # When calling the review_response_maps method
#       # Then it should return an empty array
#     end
#   end
# end
#
 end
