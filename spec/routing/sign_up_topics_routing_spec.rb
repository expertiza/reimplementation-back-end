require "rails_helper"

RSpec.describe Api::SignUpTopicsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/sign_up_topics").to route_to("api/sign_up_topics#index")
    end

    it "routes to #show" do
      expect(get: "/api/sign_up_topics/1").to route_to("api/sign_up_topics#show", id: "1")
    end

    it "routes to #create" do
      expect(post: "/api/sign_up_topics").to route_to("api/sign_up_topics#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/api/sign_up_topics/1").to route_to("api/sign_up_topics#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/api/sign_up_topics/1").to route_to("api/sign_up_topics#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/api/sign_up_topics/1").to route_to("api/sign_up_topics#destroy", id: "1")
    end
  end
end