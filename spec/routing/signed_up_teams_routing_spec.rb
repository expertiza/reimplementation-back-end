require 'rails_helper'

RSpec.describe SignedUpTeamsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/signed_up_teams').to route_to('signed_up_teams#index')
    end

    it 'routes to #show' do
      expect(get: '/signed_up_teams/1').to route_to('signed_up_teams#show', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/signed_up_teams').to route_to('signed_up_teams#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/signed_up_teams/1').to route_to('signed_up_teams#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/signed_up_teams/1').to route_to('signed_up_teams#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/signed_up_teams/1').to route_to('signed_up_teams#destroy', id: '1')
    end
  end
end
