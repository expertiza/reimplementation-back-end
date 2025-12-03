require "rails_helper"

RSpec.describe "Import API", type: :request do
  #
  # Disable BOTH authentication layers:
  #   • JwtToken.authenticate_request!
  #   • Authorization.authorize
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
  # Stub a fake model class for import operations
  #
  before do
    stub_const("FakeModel", Class.new do
      class << self
        attr_accessor :mandatory_fields, :optional_fields, :external_fields
      end

      def self.try_import_records(*args); end
    end)

    allow(FakeModel).to receive(:mandatory_fields).and_return(["id", "name"])
    allow(FakeModel).to receive(:optional_fields).and_return(["email"])
    allow(FakeModel).to receive(:external_fields).and_return(["mentor_id"])
    allow(FakeModel).to receive(:try_import_records)
  end

  #
  # Fixture file used for import
  #
  let(:file_path) { Rails.root.join("spec/fixtures/files/import_test.csv") }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(file_path, "text/csv") }

  # ------------------------------------------------------------
  # BASIC TESTS
  # ------------------------------------------------------------

  describe "GET /import/:class" do
    it "returns metadata with status 200" do
      get "/import/FakeModel"

      expect(response.status).to eq(200)

      json = JSON.parse(response.body)
      expect(json["mandatory_fields"]).to eq(["id", "name"])
      expect(json["optional_fields"]).to eq(["email"])
      expect(json["external_fields"]).to eq(["mentor_id"])
      expect(json["available_actions_on_dup"]).to eq([])
    end
  end

  describe "POST /import/:class" do
    it "returns 201 when import succeeds" do
      post "/import/FakeModel",
           params: {
             csv_file: uploaded_file,
             use_headers: true,
             ordered_fields: ["id", "name"].to_json
           }

      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)["message"])
        .to eq("FakeModel has been imported!")
    end

    it "returns 422 when import raises an error" do
      allow(FakeModel).to receive(:try_import_records)
                            .and_raise(StandardError.new("BOOM"))

      post "/import/FakeModel",
           params: {
             csv_file: uploaded_file,
             use_headers: true
           }

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["error"]).to eq("BOOM")
    end
  end

  # ------------------------------------------------------------
  # ADDITIONAL EDGE CASE TESTS
  # ------------------------------------------------------------

  describe "Additional ImportController tests" do
    it "returns 500 if class constantization fails" do
      get "/import/ThisModelDoesNotExist"

      expect(response.status).to eq(500)
      expect(response.body).to include("uninitialized constant")
    end

    it "returns 201 even if csv_file is missing (controller allows nil file)" do
      post "/import/FakeModel", params: { use_headers: true }

      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)["message"])
        .to eq("FakeModel has been imported!")
    end

    it "allows POST without ordered_fields" do
      post "/import/FakeModel",
           params: {
             csv_file: uploaded_file,
             use_headers: "false"
           }

      expect(response.status).to eq(201)
    end

    it "correctly passes use_headers as boolean" do
      post "/import/FakeModel",
           params: {
             csv_file: uploaded_file,
             use_headers: "false",
             ordered_fields: ["id"].to_json
           }

      expect(FakeModel)
        .to have_received(:try_import_records)
              .with(
                kind_of(ActionDispatch::Http::UploadedFile),
                ["id"],
                use_header: false
              )
    end

    it "returns 422 for malformed ordered_fields JSON" do
      post "/import/FakeModel",
           params: {
             csv_file: uploaded_file,
             use_headers: true,
             ordered_fields: "{ this is invalid json"
           }

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end
end
