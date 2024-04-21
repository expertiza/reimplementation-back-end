require 'swagger_helper'

describe 'Grades API' do
  path '/api/v1/grades/update/{id}' do
    put 'Updates a grade' do
      tags 'Grades'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :integer
      parameter name: :grade, in: :body, schema: {
        type: :object,
        properties: {
          score: { type: :integer },
        },
        required: ['score']
      }

      response '200', 'grade updated' do
        let(:id) { Grade.create(score: 1).id }
        let(:grade) { { score: 5 } }
        run_test!
      end

      response '404', 'grade not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
