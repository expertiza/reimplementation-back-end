require 'swagger_helper'
require 'spec_helper'
require 'rails_helper'

RSpec.describe 'api/v1/participants', type: :request do

  # test to check index with Assignment model and id
  path '/api/v1/participants/index/{model}/{id}' do
    parameter name: 'model', in: :path, type: :string, description: "Course or Assignment"
    parameter name: 'id', in: :path, type: :integer, description: "id of the course or assignment"

    # mocking of model and participant array to return array of participants
    let(:model) { 'Assignment' }
    let(:id) { 1 }
    let(:participants) {[instance_double(Participant)]}
    let(:assignment_instance) {instance_double(Assignment)}

    # stubbing methods in the mock objects
    before do
      assignment_instance = instance_double(Assignment)
      allow(Assignment).to receive(:find).with(id).and_return(assignment_instance)
      allow_any_instance_of(Assignment).to receive(:participants).and_return(participants)
      allow(assignment_instance).to receive(:participants).and_return(participants)
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
              example: JSON.parse(response.body, model_object: assignment_instance, participants: participants)
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
    let(:id) { 1 }
    let(:name) {'ABCD'}
    
    let(:authorization) { '123' }
    let(:user_instance) { instance_double(User) }
    let(:assignment_instance) {instance_double(Assignment)}
    let(:participant_instance) {instance_double(Participant)}
    let(:participants) {[participant_instance]}
    let(:request_body_parameters) {{user: {name: name}, participant:{can_submit: true, can_review: true, can_take_quiz: true}, model: model}}

    # adding stubs to mock objects
    before do
      allow(User).to receive(:find_by).with({name: name}).and_return(user_instance)
      allow(Assignment).to receive(:find).with(id).and_return(assignment_instance)
      allow(assignment_instance).to receive(:participants).and_return(Participant)
      allow(user_instance).to receive(:id).and_return(23)
      allow(Participant).to receive(:find_by).with({user_id: user_instance.id}).and_return(participant_instance)
      allow(participant_instance).to receive(:present?).and_return(true)
      allow(user_instance).to receive(:name).and_return(name)
      allow(assignment_instance).to receive(:id).and_return(1)
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
        before do
          allow(participant_instance).to receive(:present?).and_return(false)
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant_instance)
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
    let(:old_handle) {'old_handle'}
    let(:new_handle) { 'new_handle' }
    let(:assignment_participant_instance) {instance_double(AssignmentParticipant)}
    let(:participant_instance) {instance_double(Participant)}
    let(:participant) {{handle: old_handle}}
    let(:request_body_parameters) {{participant: participant}}
    let(:participant_params) {ActionController::Parameters.new(handle: old_handle)}
    let(:dummy_object) {instance_double (Object)}

    # stubbing methods on mock objects
    before do
      allow(AssignmentParticipant).to receive(:find).with(id).and_return(assignment_participant_instance)
      allow(assignment_participant_instance).to receive(:handle).and_return(old_handle)
      allow(assignment_participant_instance).to receive(:update).with(participant_params.permit!).and_return(true)
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
        let(:participant) {{handle: new_handle}}
        let(:request_body_parameters) {{participant: participant}}
        let(:participant_params) {ActionController::Parameters.new(handle: new_handle)}
        before do
          allow(assignment_participant_instance).to receive(:update).with(participant_params.permit!).and_return(true)
          allow(assignment_participant_instance).to receive(:errors).and_return("error")
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant)
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
          allow(assignment_participant_instance).to receive(:update).with(participant_params.permit!).and_return(false)
          allow(assignment_participant_instance).to receive(:errors).and_return("error")
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: assignment_participant_instance.errors)
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
    let(:participant_instance) {instance_double(Participant)}

    # stubbing methods on mock objects
    before do
      allow(Participant).to receive(:find).with(id).and_return(participant_instance)
      allow(participant_instance).to receive(:update).and_return({:can_submit=>true, :can_review=>true, :can_take_quiz=>true})
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

      let(:participant) {{can_submit: true, can_review: true, can_take_quiz: true}}
      let(:authorizations) {participant}

      # ok response after updating authorizations
      response(200, 'ok') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, participant: participant_instance)
            }
          }
        end
        run_test!
      end

      # error request
      response(422, 'invalid request') do
        before do
          allow(participant_instance).to receive(:update).and_return(false)
          allow(participant_instance).to receive(:errors).and_return("error")
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: participant_instance.errors)
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
    let(:assignment_instance) {instance_double(Assignment, id: id)}
    let(:course_instance) {instance_double(Course)}
    let(:participant_instance) {instance_double(Participant)}
    let(:participants) {[]}

    # stubbing methods on mock objects
    before do
      allow(Assignment).to receive(:find).with(id).and_return(assignment_instance)
      allow(assignment_instance).to receive(:course).and_return(nil)
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
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
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
        let(:participants) {[participant_instance]}
        before do
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
          allow(course_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_instance).to receive(:name).and_return('Assignment Name')
          allow(participant_instance).to receive(:copy)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "All of #{course_instance.name} participants are already in #{assignment_instance.name}")
            }
          }
        end
        run_test!
      end

      # "created" response after inherit is complete
      response(201, 'created') do
        let(:participants) {[participant_instance]}
        before do
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
          allow(course_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_instance).to receive(:name).and_return('Assignment Name')
          allow(participant_instance).to receive(:copy).with(id).and_return(true)
          allow(Participant).to receive(:any?).and_return(true)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "The participants from #{course_instance.name} were copied to #{assignment_instance.name}")
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
    let(:assignment_instance) {instance_double(Assignment, id: id)}
    let(:course_instance) {instance_double(Course, id: 7)}
    let(:participant_instance) {instance_double(Participant)}
    let(:participants) {[]}

    # stubbing methods on mock objects
    before do
      allow(Assignment).to receive(:find).with(id).and_return(assignment_instance)
      allow(assignment_instance).to receive(:course).and_return(nil)
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

      response(404, 'resource not found') do
        before do
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
          allow(assignment_instance).to receive(:participants).and_return(participants)
          allow(assignment_instance).to receive(:name).and_return('Assignment Name')
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "No participants were found for this #{assignment_instance.name}")
            }
          }
        end
        run_test!
      end

      # ok response after copy completes
      response(200, 'ok') do
        let(:participants) {[participant_instance]}
        before do
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
          allow(assignment_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_instance).to receive(:name).and_return('Assignment Name')
          allow(participant_instance).to receive(:copy)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, note: "All of #{course_instance.name} participants are already in #{assignment_instance.name}")
            }
          }
        end
        run_test!
      end

      # "created" response after bequeath is complete
      response(201, 'created') do
        let(:participants) {[participant_instance]}
        before do
          allow(assignment_instance).to receive(:course).and_return(course_instance)
          allow(course_instance).to receive(:nil?).and_return(false)
          allow(assignment_instance).to receive(:participants).and_return(participants)
          allow(course_instance).to receive(:name).and_return('Course Name')
          allow(assignment_instance).to receive(:name).and_return('Assignment Name')
          allow(participant_instance).to receive(:copy).with(7).and_return(true)
          allow(Participant).to receive(:any?).and_return(true)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "The participants from #{course_instance.name} were copied to #{assignment_instance.name}")
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
    # mocking objects required for this method call
    let(:id) { 1 }
    let(:participant_instance) {instance_double(Participant)}
    let(:an_object) {instance_double(Object)}
    
    # stubbing methods to the mock objects
    before do
      allow(Participant).to receive(:find).with(id).and_return(participant_instance)
      allow(participant_instance).to receive(:team).and_return(an_object)
      allow(an_object).to receive(:present?).and_return(false)
      allow(participant_instance).to receive(:destroy).and_return(true)
      allow(participant_instance).to receive_message_chain(:user, :name).and_return('John Doe')
    end

    # DELETE Request to participant
    delete('delete participant') do
      tags 'Participants'
      produces 'application/json'
      # error because participant is on a team
      response(422, 'invalid request') do
        before do
          allow(an_object).to receive(:present?).and_return(true)
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, error: "This participant is on a team")
            }
          }
        end
        run_test!
      end

      # ok response after delete is complete
      response(200, 'ok') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, message: "#{participant_instance.user.name} was successfully removed as a participant")
            }
          }
        end
        run_test!
      end

      # error if destroy participant produces error
      response(422, 'invalid request') do
        before do
          allow(participant_instance).to receive(:destroy).and_return(false)
        end
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