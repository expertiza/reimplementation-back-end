# frozen_string_literal: true

class Api::V1::DutiesController < ApplicationController
  before_action :set_duty, only: %i[show edit update destroy]

  def index
    @duties = Duty.all
  end

  def show; end

  def new
    @duty = Duty.new
    @id = params[:id]
  end

  def edit; end

  def create
    @duty = Duty.new(duty_params)

    if @duty.save
      redirect_to redirect_to_url, notice: 'Role was successfully created.'
    else
      redirect_to_create_page_and_show_error
    end
  end

  def update
    if @duty.update(duty_params)
      redirect_to redirect_to_url, notice: 'Role was successfully updated.'
    else
      redirect_to_create_page_and_show_error
    end
  end

  def destroy
    @duty.destroy
    redirect_to redirect_to_url, notice: 'Role was successfully deleted.'
  end

  private

  def set_duty
    @duty = Duty.find(params[:id])
  end

  def redirect_to_edit_assignment_path
    redirect_to edit_assignment_path(duty_params[:assignment_id])
  end

  def redirect_to_create_page_and_show_error
    # flash[:error] = @duty.errors.full_messages.join('. ')
    redirect_to action: :new, id: duty_params[:assignment_id]
  end

  def duty_params
    params.require(:duty).permit(:assignment_id, :max_members_for_duty, :name)
  end
end

def redirect_to_url
  "/api/v1/duties"
end
