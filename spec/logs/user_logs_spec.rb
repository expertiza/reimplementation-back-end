require 'rails_helper'

RSpec.describe User do
  let(:user) { build(:user, name: "Jane", email: "jdoe@ncsu.edu", full_name: "Jane Doe") }
  let(:params) do { user: {
        "name": "Jane Doe",
        "full_name": "Jane Doe",
        "email": "jane.doe@example.com",
        "role_id": 1,
        "institution_id": 1,
        "password": "password",
        "password_confirmation": "password"   } }
  end

  # https://everydayrails.com/2020/08/10/rails-log-message-testing-rspec
  # Rails testing
  it "logs when user is created" do
    allow(Rails.logger).to receive(:info)
    expect(Rails.logger).to receive(:info)

    post :create, params: params
  end

end
