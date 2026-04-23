# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RevisionRequestsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/revision_requests').to route_to('revision_requests#index')
    end

    it 'routes to #show' do
      expect(get: '/revision_requests/1').to route_to('revision_requests#show', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/revision_requests/1').to route_to('revision_requests#update', id: '1')
    end

    it 'routes to #update via PUT' do
      expect(put: '/revision_requests/1').to route_to('revision_requests#update', id: '1')
    end
  end
end
