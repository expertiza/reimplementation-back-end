require 'swagger_helper'

describe Api::V1::BadgesController do
  describe "index" do
    it "returns all badges" do
      request.headers['Authorization'] = 'eyJhbGciOiJSUzI1NiJ9.eyJpZCI6MSwibmFtZSI6ImFkbWluIiwiZnVsbF9uYW1lIjoiYWRtaW4gYWRtaW4iLCJyb2xlIjoiU3VwZXIgQWRtaW5pc3RyYXRvciIsImluc3RpdHV0aW9uX2lkIjoxLCJleHAiOjE2OTkzMjU3Mzl9.e_O2S65agUCih-klyShyfujz0GGJqzz2IcYXEPq_NOWiyd9iFR-gpdUiSqeqWuHA9XcokzEw_41HXSPLRo00xchPXUiUzEwKeZ0wL2ghrPUk07MNyC9IoDfC5ZTIDmAoZ2OgdCPSyUtVRoavkwycyb9hOVh-X6ZLorsdo_t0a7JbL2N6ut_Hcz2zJTPyBD6LNMVqsLflWQl71LGC3PxzI_yevLembFCVPqY2nR41LKmKOxmK52JcAKJx9AO_rLRtZ9vws-HVcrgHphQ-URVNg6JbgqZpaLKV_XV4iP8wlR06YUcNjx2b2hhbweeVe0y-vt6hPO0lt1fj2w1H7sF_sQ'
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_empty
    end

    it "returns a successful response status" do
    # Test scenario 1: When the request is successful
    # Expected behavior: The response status should be 200 (OK)
    # Test scenario 2: When there is an error in retrieving the badges
    # Expected behavior: The response status should indicate an error
    end
  end
end