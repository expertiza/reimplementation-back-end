require 'rails_helper'

RSpec.describe Api::V1::StudentTasksController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/api/v1/student_tasks').to route_to('api/v1/student_tasks#index')
    end

    it 'routes to #show' do
      expect(get: '/api/v1/student_tasks/1').to route_to('api/v1/student_tasks#show', id: '1')
    end

    it 'routes to #list' do
      expect(get: '/api/v1/student_tasks/list').to route_to('api/v1/student_tasks#list')
    end

    it 'routes to #view' do
      expect(get: '/api/v1/student_tasks/view').to route_to('api/v1/student_tasks#view')
    end

    it 'does not route to #create' do
      expect(post: '/api/v1/student_tasks').not_to be_routable
    end

    it 'does not route to #update via put' do
      expect(put: '/api/v1/student_tasks/1').not_to be_routable
    end

    it 'does not route to #update via patch' do
      expect(patch: '/api/v1/student_tasks/1').not_to be_routable
    end

    it 'does not route to #destroy' do
      expect(delete: '/api/v1/student_tasks/1').not_to be_routable
    end
  end
end
