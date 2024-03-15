require 'swagger_helper'
require 'spec_helper'
require 'rails_helper'

RSpec.describe 'api/v1/participants', type: :request do

  let(:participant1) { FactoryBot.build(:participant, user: FactoryBot.build(:student, name: 'Jane', fullname: 'Doe, Jane', id: 1), handle: 'handle')}
  let(:participant2) { FactoryBot.build(:participant, user: FactoryBot.build(:student, name: 'John', fullname: 'Doe, John', id: 2)) }
  let(:participant3) { FactoryBot.build(:participant, id: 3, can_review: false, user: FactoryBot.build(:student, name: 'King', fullname: 'Titan, King', id: 3)) }
  let(:participant5) { FactoryBot.build(:participant, id: 5, user: FactoryBot.build(:student, name: 'John', fullname: 'Doe, John', id: 23)) }
  let(:assignment1) {FactoryBot.build(:assignment, id: 13, name: 'Assignment Name')}
  let(:user1) { FactoryBot.build(:student, id: 6, name: 'no name', fullname: 'no two') }
  let(:assignment_participant1) {FactoryBot.build(:assignment_participant, id:19)}

  # test to check index with Assignment model and id
  path '/api/v1/participants/index/{model}/{id}' do
    parameter name: 'model', in: :path, type: :string, description: "Course or Assignment"
    parameter name: 'id', in: :path, type: :integer, description: "id of the course or assignment"

    # mocking of model and participant array to return array of participants
    let(:model) { 'Assignment' }
    let(:id) { 13 }

    # stubbing methods in the mock objects
    before do
      assignment_instance = instance_double(Assignment)
      allow(Assignment).to receive(:find).with(id).and_return(assignment1)
      allow(assignment1).to receive(:participants).and_return(participant1)
    end

    # GET request to index method
    get('list participants') do
      tags 'Participants'
      produces 'application/json'

      # ok response giving a list of (empty) participants of a given assignment
      response(200, 'ok') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, model_object: assignment1, participants: participant1)
            }
          }
        end
        run_test!
      end

      # error for invalid parameters
      response(422, 'invalid request') do

        # stubbing method to test 404 error
        before do
          allow(Assignment).to receive(:find).with(id).and_return(nil)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "Invalid required parameters")
            }
          }
        end
        run_test!
      end

    end
  end

  # test to create a new participant
  path '/api/v1/participants/{model}/{id}' do
    parameter name: 'model', in: :path, type: :string, description: "Course or Assignment"
    parameter name: 'id', in: :path, type: :integer, description: 'id of the course or assignment'

    # mocking models required for method execution
    let(:model) { 'Assignment' }
    let(:id) { 6 }
    let(:name) {'ABCD'}

    let(:authorization) { '123' }
    let(:assignment_instance) {instance_double(Assignment)}
    let(:result) {}
    let(:request_body_parameters) {{user: {name: name}, participant:{can_submit: true, can_review: true, can_take_quiz: true}, model: model}}

    # adding stubs to mock objects
    before do
      allow(User).to receive(:find_by).with({name: name}).and_return(user1)
      allow(Assignment).to receive(:find).with(id).and_return(assignment_instance)
      allow(assignment_instance).to receive(:participants).and_return(Participant)
    end

    # POST Request to create method
    post('create participant') do
      tags 'Participants'
      consumes 'application/json'
      produces 'application/json'

      # mocking adding request body parameters
      parameter name: :request_body_parameters, in: :body, schema: {
        type: :object,
        properties: {
          user: { type: :object, properties: {name: :string} },
          participant: { type: :object, properties: {can_submit: :boolean, can_review: :boolean, can_take_quiz: :boolean} }
        }
      }
      let(:user) {{name: name}}

      # error response for when user does not exist
      response(404, 'resource not found') do
        before do
          allow(User).to receive(:find_by).with({name: name}).and_return(nil)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "User #{request_body_parameters[:user][:name]} does not exist")
            }
          }
        end
        run_test!
      end

      # ok response when participant already exists
      response(200, 'ok') do
        before do
          allow(Participant).to receive(:find_by).with({user_id: user1.id}).and_return(participant1)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "Participant #{request_body_parameters[:user][:name]} already exists for this #{request_body_parameters[:model]}")
            }
          }
        end
        run_test!
      end

      # "created" response when participant is created
      response(201, 'created') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant1)
            }
          }
        end
        run_test!
      end


    end
  end

  # test to update handle of participant
  path '/api/v1/participants/update_handle/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the participant'

    # mocking models required for method execution
    let(:id) {1}
    let(:old_handle) {'handle'}
    let(:new_handle) { 'new_handle' }
    let(:assignment_participant_instance) {instance_double(AssignmentParticipant)}
    let(:participant) {{handle: old_handle}}
    let(:request_body_parameters) {{participant: participant}}
    let(:participant_params) {ActionController::Parameters.new(handle: old_handle)}

    # stubbing methods on mock objects
    before do
      allow(AssignmentParticipant).to receive(:find).with(id).and_return(assignment_participant1)
      allow(assignment_participant1).to receive(:handle).and_return(old_handle)
      allow(assignment_participant1).to receive(:update).with(participant_params.permit!).and_return(true)
    end

    # patch Request to update_handle method
    patch('update the handle of the assignment participant') do
      tags 'Participants'
      consumes 'application/json'
      produces 'application/json'

      # mocking request body parameters
      parameter name: :request_body_parameters, in: :body, schema: {
        type: :object,
        properties:{
          participant: {type: :object, properties: {handle: :string}}
        }
      }

      # ok response saying that handle already exists
      response(200, 'ok') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "Handle already in use")
            }
          }
        end
        run_test!
      end

      # ok response saying that handle has been changed
      response(200, 'ok') do
        let(:participant_handle) {{handle: new_handle}}
        let(:request_body_parameters) {{participant: participant}}
        let(:participant_params) {ActionController::Parameters.new(handle: new_handle)}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant_handle)
            }
          }
        end
        run_test!
      end

      # error response because the update method on participant model failed
      response(422, 'invalid request') do
        let(:participant) {{handle: new_handle}}
        let(:request_body_parameters) {{participant: participant}}
        let(:participant_params) {ActionController::Parameters.new(handle: new_handle)}
        before do
          allow(assignment_participant1).to receive(:update).with(participant_params.permit!).and_return(false)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: assignment_participant1.errors)
            }
          }
        end
        run_test!
      end
    end
  end

  # test to update authorizations for a participant
  path '/api/v1/participants/update_authorization/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the participant'

    # mocking models required
    let(:id) { 1 }

    # stubbing methods on mock objects
    before do
      allow(Participant).to receive(:find).with(id).and_return(participant1)
      allow(participant1).to receive(:update).and_return({:can_submit=>true, :can_review=>true, :can_take_quiz=>true})
    end

    # PATCH request to update_authorizations method of participant
    patch('update the authorization of the participant ') do
      tags 'Participants'
      produces 'application/json'
      consumes 'application/json'

      # mocking adding request body parameters
      parameter name: :authorizations, in: :body, schema: {
        type: :object,
        properties: {
          participant: { type: :object, properties: {can_submit: :boolean, can_review: :boolean, can_take_quiz: :boolean} }
        }
      }

      let(:participant_authorizations) {{can_submit: true, can_review: true, can_take_quiz: true}}
      let(:authorizations) {participant_authorizations}

      # ok response after updating authorizations
      response(200, 'ok') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant1)
            }
          }
        end
        run_test!
      end

      # error request
      response(422, 'invalid request') do
        before do
          allow(participant1).to receive(:update).and_return(false)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: participant1.errors)
            }
          }
        end
        run_test!
      end
    end
  end

  #test to "inherit" participants from Course to Assignment
  path '/api/v1/participants/inherit/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the assignment'

    # mocking models that are required for method execution
    let(:id) {13}
    let(:course_instance) {instance_double(Course)}
    let(:participants) {[]}

    # stubbing methods on mock objects
    before do
      allow(Assignment).to receive(:find).with(id).and_return(assignment1)
      allow(assignment1).to receive(:course).and_return(nil)
    end

    # GET Request to inherit method
    get('inherit participants from course to assignment') do
      tags 'Participants'
      produces 'application/json'
      # Error response for when assignment has no course
      response(422, 'invalid request') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "No course was found for this assignment")
            }
          }
        end
        run_test!
      end

      # error response for when there are no participants
      response(404, 'resource not found') do
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "No participants were found for this #{course_instance.name}")
            }
          }
        end
        run_test!
      end

      # ok response after "inheriting" participants from course to assignment
      response(200, 'ok') do
        let(:participants) {[assignment_participant1]}
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_participant1).to receive(:copy)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "All of #{course_instance.name} participants are already in #{assignment1.name}")
            }
          }
        end
        run_test!
      end

      # "created" response after inherit is complete
      response(201, 'created') do
        let(:participants) {[assignment_participant1]}
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_participant1).to receive(:copy).with(id).and_return(true)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "The participants from #{course_instance.name} were copied to #{assignment1.name}")
            }
          }
        end
        run_test!
      end
    end
  end

  # test to "inherit" participants from Assignment to Course
  path '/api/v1/participants/bequeath/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the assignment'

    # Mocking models that are required
    let(:id) {13}
    #let(:assignment_instance) {instance_double(Assignment, id: id)}
    let(:course_instance) {instance_double(Course, id: 7)}
    let(:course_participant_instance) {instance_double(CourseParticipant)}
    let(:participants) {[]}

    # stubbing methods on mock objects
    before do
      allow(Assignment).to receive(:find).with(id).and_return(assignment1)
      allow(assignment1).to receive(:course).and_return(nil)
    end

    # GET request to bequeath methof
    get('bequeaths participants from assignment to course') do
      tags 'Participants'
      produces 'application/json'
      # error response from when Course Has no such assignment
      response(422, 'invalid request') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "No course was found for this assignment")
            }
          }
        end
        run_test!
      end

      # error for Course has no Participants
      response(404, 'resource not found') do
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(assignment1).to receive(:participants).and_return(participants)
          #allow(assignment_instance).to receive(:name).and_return('Assignment Name')
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "No participants were found for this #{assignment1.name}")
            }
          }
        end
        run_test!
      end

      # ok response after copy completes
      response(200, 'ok') do
        let(:participants) {[course_participant_instance]}
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(assignment1).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(course_participant_instance).to receive(:copy)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "All of #{course_instance.name} participants are already in #{assignment1.name}")
            }
          }
        end
        run_test!
      end

      # "created" response after bequeath is complete
      response(201, 'created') do
        let(:participants) {[course_participant_instance]}
        before do
          allow(assignment1).to receive(:course).and_return(course_instance)
          allow(assignment1).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(course_participant_instance).to receive(:copy).with(7).and_return(true)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "The participants from #{course_instance.name} were copied to #{assignment1.name}")
            }
          }
        end
        run_test!
      end
    end
  end

  # test to destroy participants
  path '/api/v1/participants/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the participant'
    let(:id) { 19 }
    #let(:assignment_participant_instance) {instance_double(AssignmentParticipant)}
    # stubbing methods to the mock objects
    before do
      allow(Participant).to receive(:find).with(id).and_return(participant1)
    end

    # DELETE Request to participant
    delete('delete participant') do
      tags 'Participants'
      produces 'application/json'

      # ok response after delete is complete
      response(200, 'ok') do
        before do
          allow(participant1).to receive(:delete)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "#{participant1.user.name} was successfully removed as a participant")
            }
          }
        end
        run_test!
      end

      # error if destroy participant produces error
      response(422, 'invalid request') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "Failed to remove participant")
            }
          }
        end
        run_test!
      end

    end
  end

end