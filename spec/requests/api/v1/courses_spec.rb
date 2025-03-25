require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'api/v1/courses', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:prof) {
    User.create(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
    )
  }

  let(:token) { JsonWebToken.encode({ id: prof.id }) }
  let(:Authorization) { "Bearer #{token}" }

  # GET /courses/{id}/add_ta/{ta_id}
  path '/api/v1/courses/{id}/add_ta/{ta_id}' do
    parameter name: :id, in: :path, type: :integer, required: true
    parameter name: :ta_id, in: :path, type: :integer, required: true
    let(:institution) { Institution.create(name: "NC State") }
    let(:ta) {
      User.create(
        name: "taa",
        password_digest: "password",
        role_id: @roles[:ta].id,
        full_name: "TA A",
        email: "testuser@example.com",
        mru_directory_path: "/home/testuser",
      )
    }
    let(:course) {
      Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                    info: 'blank')
    }
    let(:id) { course.id }
    let(:ta_id) { ta.id }
    get('add_ta course') do
      tags 'Courses'
      produces 'application/json'
      response(201, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
      response(400, 'bad request') do
        let(:invalid_course_id) { 'invalid_course_id' }
        let(:invalid_ta_id) { 'invalid_ta_id' }
        let(:id) { invalid_course_id }
        let(:ta_id) { invalid_ta_id }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              error: 'TA could not be added to the course'
            }
          }
        end
      end
    end
  end

  # GET /courses/{id}/tas
  path '/api/v1/courses/{id}/tas' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:institution) { Institution.create(name: "NC State") }
    let(:course) {
      Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                    info: 'blank')
    }
    let(:id) { course.id }
    get('view_tas course') do
      tags 'Courses'
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  # GET /courses/{id}/remove_ta/{ta_id}
  path '/api/v1/courses/{id}/remove_ta/{ta_id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    parameter name: 'ta_id', in: :path, type: :string, description: 'ta_id'
    let(:institution) { Institution.create(name: "NC State") }
    let(:course) {
      Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                    info: 'blank')
    }
    let(:id) { course.id }
    let(:ta) {
      User.create(
        name: "taa",
        password_digest: "password",
        role_id: @roles[:ta].id,
        full_name: "TA A",
        email: "testuser@example.com",
        mru_directory_path: "/home/testuser",
      )
    }
    let(:ta_id) { ta.id }
    let(:ta_mapping) { TaMapping.create(course_id: course.id, ta_id: ta.id) }
    get('remove_ta course') do
      tags 'Courses'
      consumes 'application/json'
      produces 'application/json'
      response(200, 'successful') do
        before do
          allow_any_instance_of(Course).to receive(:remove_ta).and_return({ success: true, ta_name: ta.name })
        end
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: { message: "The TA taa has been removed." }
            }
          }
        end
        run_test!
      end

      response(200, 'TA removed message is internationalized') do
        let!(:hindi_user) do
          User.create!(
            name: "hindiuser",
            full_name: "Hindi User",
            email: "hindi@example.com",
            password_digest: "password",
            role_id: @roles[:instructor].id,
            locale: :hi
          )
        end
  
        let(:token) { JsonWebToken.encode({ id: hindi_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
  
        before do
          allow_any_instance_of(Course).to receive(:remove_ta).and_return({ success: true, ta_name: ta.name })
        end
  
        run_test! do |response|
          data = JSON.parse(response.body)
          expected_message = I18n.t('course.ta_removed', ta_name: ta.name, locale: :hi)
          expect(response).to have_http_status(:ok)
          expect(data['message']).to eq(expected_message)
        end
      end
    end
  end

  # GET /courses/{id}/copy
  path '/api/v1/courses/{id}/copy' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:institution) { Institution.create(name: "NC State") }
    let(:course) {
      Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                    info: 'blank')
    }
    let(:id) { course.id }
    get('copy course') do
      tags 'Courses'
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  # GET /courses/
  path '/api/v1/courses' do
    get('list courses') do
      tags 'Courses'
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    # POST /courses/
    post('create course') do
      tags 'Courses'
      consumes 'application/json'
      parameter name: :course, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          directory_path: { type: :string },
          instructor_id: { type: :integer },
          institution_id: { type: :integer },
          info: { type: :string }
        },
        required: ['name', 'directory_path', 'institution_id', 'instructor_id']
      }
      response(201, 'successful') do
        let(:institution) { Institution.create(name: "NC State") }
        let(:course) {
          { institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
            info: 'blank' }
        }
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  # GET /courses/{id}
  path '/api/v1/courses/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:institution) { Institution.create(name: "NC State") }
    let(:course) {
      Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                    info: 'blank')
    }
    let(:id) { course.id }
    get('show course') do
      tags 'Courses'
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    # PATCH /courses/{id}
    patch('update course') do
      tags 'Courses'
      consumes 'application/json'
      parameter name: :course, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          directory_path: { type: :string },
          instructor_id: { type: :integer },
          institution_id: { type: :integer },
          info: { type: :string }
        },
        required: %w[]
      }
      let(:institution) { Institution.create(name: "NC State") }
      let(:course) {
        Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                      info: 'blank')
      }
      let(:id) { course.id }
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    # PUT /courses/{id}
    put('update course') do
      tags 'Courses'
      consumes 'application/json'
      parameter name: :course, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          directory_path: { type: :string },
          instructor_id: { type: :integer },
          institution_id: { type: :integer },
          info: { type: :string }
        },
        required: %w[]
      }
      let(:institution) { Institution.create(name: "NC State") }
      let(:course) {
        Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                      info: 'blank')
      }
      let(:id) { course.id }
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    # DELETE /courses/{id}
    delete('delete course') do
      tags 'Courses'
      let(:institution) { Institution.create(name: "NC State") }
      let(:course) {
        Course.create(institution_id: institution.id, instructor_id: prof.id, directory_path: 'samplepath', name: 'OODD',
                      info: 'blank')
      }
      let(:id) { course.id }
      response(204, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: response.body
            }
          }
        end
        run_test!
      end
      response(404, 'Course not found in Hindi') do
        let(:id) { 999 } # Non-existent course ID
      
        let!(:hindi_user) do
          User.create!(
            name: "hindiuser",
            full_name: "Hindi User",
            email: "hindi@example.com",
            password_digest: "password",
            role_id: @roles[:instructor].id,
            locale: :hi
          )
        end
      
        let(:token) { JsonWebToken.encode({ id: hindi_user.id }) }
        let(:Authorization) { "Bearer #{token}" }
      
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response).to have_http_status(:not_found)
          expect(data['error']).to eq(I18n.t('course.not_found', locale: :hi, id: id))
        end
      end      
    end
  end
  
end
