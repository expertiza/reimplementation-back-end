# frozen_string_literal: true

class Api::V1::DutiesController < ApplicationController
  before_action :set_duty, only: %i[show edit update destroy]

  def index
    @duties = Duty.all
    render json: @duties
  end

  def new
    @duty = Duty.new
    @id = params[:id]
  end

  def show
    render json: @duty
  end

  def edit
    render json: @duty
  end

  def create
    @duty = Duty.new(duty_params)

    if @duty.save
      render json: @duty, status: :created
    else
      render json: { error: @duty.errors.full_messages.join('. ') }, status: :unprocessable_entity
    end
  end

  def update
    if @duty.update(duty_params)
      render json: @duty
    else
      render json: { error: @duty.errors.full_messages.join('. ') }, status: :unprocessable_entity
    end
  end

  def destroy
    @duty.destroy
    render json: { message: "Duty was successfully destroyed." }, status: :ok
  end

  private

  def set_duty
    @duty = Duty.find(params[:id])
  end

  def duty_params
    params.require(:duty).permit(:assignment_id, :max_members_for_duty, :name)
  end
end
