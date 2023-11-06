require 'rails_helper'

RSpec.describe Api::V1::DutiesController, type: :controller do
  describe "index" do
    it "returns all duties" do
      # Test scenario 1: When there are duties in the database
      # Expect the method to return all duties in JSON format
      duty1 = Duty.create(name: 'Duty 1')
      duty2 = Duty.create(name: 'Duty 2')
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
                                             { 'name' => 'Duty 1' },
                                             { 'name' => 'Duty 2' }
                                           )
    end

    it "returns an empty JSON array when there are no duties" do
      # Test scenario 2: When there are no duties in the database
      # Expect the method to return an empty JSON array
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "#new" do
    context "when called" do
      it "initializes a new Duty object" do
        get :new
        expect(assigns(:duty)).to be_a_new(Duty)
      end

      it "assigns the value of params[:id] to @id" do
        id = 123
        get :new, params: { id: id }
        expect(assigns(:id)).to eq(id)
      end
    end
  end

  describe "#show" do
    context "when called" do
      it "renders the duty as JSON" do
        duty = Duty.create(name: 'Test Duty')
        get :show, params: { id: duty.id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('name' => 'Test Duty')
      end
    end
  end

  describe "#edit" do
    context "when called" do
      it "renders the duty as JSON" do
        duty = Duty.create(name: 'Test Duty')
        get :edit, params: { id: duty.id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('name' => 'Test Duty')
      end
    end
  end

  describe "#create" do
    context "when duty params are valid" do
      it "creates a new duty" do
        duty_params = { name: 'New Duty' }
        post :create, params: { duty: duty_params }
        expect(response).to have_http_status(:created)
        expect(Duty.last.name).to eq('New Duty')
      end

      it "returns a JSON response with the created duty and status code 201" do
        duty_params = { name: 'New Duty' }
        post :create, params: { duty: duty_params }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to include('name' => 'New Duty')
      end
    end

    context "when duty params are invalid" do
      it "does not create a new duty" do
        duty_params = { name: '' }
        post :create, params: { duty: duty_params }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(Duty.last).to be_nil
      end

      it "returns a JSON response with the error messages and status code 422" do
        duty_params = { name: '' }
        post :create, params: { duty: duty_params }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('name' => ["can't be blank"])
      end
    end
  end

  describe "#update" do
    context "when duty is successfully updated" do
      it "returns the updated duty as JSON" do
        duty = Duty.create(name: 'Old Duty')
        updated_name = 'Updated Duty'
        patch :update, params: { id: duty.id, duty: { name: updated_name } }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include('name' => updated_name)
      end
    end

    context "when duty fails to update" do
      it "returns an error message as JSON" do
        duty = Duty.create(name: 'Old Duty')
        patch :update, params: { id: duty.id, duty: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('name' => ["can't be blank"])
      end
    end
  end

  describe "#destroy" do
    it "destroys the duty" do
      duty = Duty.create(name: 'Duty to be Destroyed')
      delete :destroy, params: { id: duty.id }
      expect(response).to have_http_status(:ok)
      expect(Duty.find_by(id: duty.id)).to be_nil
    end

    it "returns an error message for a non-existent duty" do
      delete :destroy, params: { id: 9999 } # Assuming 9999 is an invalid duty ID.
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to include('message' => 'Duty not found')
    end

    it "returns an error message for a previously destroyed duty" do
      duty = Duty.create(name: 'Destroyed Duty')
      duty.destroy
      delete :destroy, params: { id: duty.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include('message' => 'Duty already destroyed')
    end
  end

  describe "#set_duty" do
    context "when a valid duty id is provided" do
      it "sets @duty to the duty with the provided id" do
        duty = Duty.create(name: 'Test Duty')
        get :show, params: { id: duty.id }
        expect(assigns(:duty)).to eq(duty)
      end
    end

    context "when an invalid duty id is provided" do
      it "does not set @duty and raises an error" do
        expect { get :show, params: { id: 9999 } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#duty_params" do
    context "when valid parameters are provided" do
      it "returns the permitted parameters for duty" do
        valid_params = { name: 'Valid Duty', assignment_id: 1, max_members_for_duties: 5 }
        duty = Duty.new(valid_params)
        duty_params = controller.send(:duty_params, duty)
        expect(duty_params).to eq(valid_params)
      end
    end

    context "when assignment_id is missing" do
      it "raises an error" do
        invalid_params = { name: 'Invalid Duty', max_members_for_duties: 5 }
        duty = Duty.new(invalid_params)
        expect { controller.send(:duty_params, duty) }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context "when max_members_for_duty is missing" do
      it "raises an error" do
        invalid_params = { name: 'Invalid Duty', assignment_id: 1 }
        duty = Duty.new(invalid_params)
        expect { controller.send(:duty_params, duty) }.to raise_error(ActionController::ParameterMissing)
      end

      context "when name is missing" do
        it "raises an error" do
          invalid_params = { assignment_id: 1, max_members_for_duties: 5 }
          duty = Duty.new(invalid_params)
          expect { controller.send(:duty_params, duty) }.to raise_error(ActionController::ParameterMissing)
        end
      end
    end
  end
end
