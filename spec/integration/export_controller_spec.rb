# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Export API", type: :request do
  #
  # Authentication + authorization bypass
  #
  before do
    allow_any_instance_of(JwtToken)
      .to receive(:authenticate_request!)
            .and_return(true)

    allow_any_instance_of(Authorization)
      .to receive(:authorize)
            .and_return(true)
  end

  #
  # Fake model used for constantize
  #
  class FakeModel
    def self.mandatory_fields; ["id", "name"]; end
    def self.optional_fields; ["email"]; end
    def self.external_fields; ["institution"]; end
  end

  describe "GET /export/:class" do
    it "returns mandatory, optional, and external fields with status 200" do
      get "/export/FakeModel"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["mandatory_fields"]).to eq(["id", "name"])
      expect(json["optional_fields"]).to eq(["email"])
      expect(json["external_fields"]).to eq(["institution"])
    end
  end

  describe "POST /export/:class" do
    it "returns 200 and calls Export.perform with ordered fields" do
      ordered_fields = ["id", "name"]
      export_return = "fake_csv_data"

      expect(Export).to receive(:perform)
                          .with(FakeModel, ordered_fields)
                          .and_return(export_return)

      post "/export/FakeModel", params: {
        ordered_fields: ordered_fields.to_json
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["message"]).to eq("FakeModel has been exported!")
      expect(json["file"]).to eq("fake_csv_data")
    end

    it "passes nil ordered_fields when none are provided" do
      export_return = "csv_without_ordering"

      expect(Export).to receive(:perform)
                          .with(FakeModel, nil)
                          .and_return(export_return)

      post "/export/FakeModel"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["file"]).to eq("csv_without_ordering")
    end

    it "returns 422 if constantize fails" do
      post "/export/DoesNotExist"

      expect(response.status).to eq(422)
    end

    it "returns 422 if Export.perform raises an error" do
      allow(Export).to receive(:perform)
                         .and_raise(StandardError.new("Boom!"))

      post "/export/FakeModel", params: { ordered_fields: ["id"].to_json }

      expect(response.status).to eq(422)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Boom!")
    end

    it "returns 422 if ordered_fields is invalid JSON" do
      post "/export/FakeModel", params: {
        ordered_fields: "not-json"
      }

      expect(response.status).to eq(422)
    end
  end
end
