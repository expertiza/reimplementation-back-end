class Api::V1::DutiesController < ApplicationController

  before_action :set_assignment
  before_action :authorize_user, except: [:index, :show]
  before_action :set_duty, only: %i[show edit update destroy]

  def index
    @duties = @assignment.duties
  end

  def show
  end

  def new
    @duty = @assignment.duties.build
  end

  def edit
  end

  def create
    @duty = @assignment.duties.build(duty_params)

    if @duty.save
      redirect_to edit_assignment_path(@assignment), notice: 'Role was successfully created.'
    else
      redirect_to_create_page_and_show_error
    end
  end

  def update
    if @duty.update(duty_params)
      redirect_to edit_assignment_path(@assignment), notice: 'Role was successfully updated.'
    else
      redirect_to_create_page_and_show_error
    end
  end

  def destroy
    @duty.destroy
    redirect_to edit_assignment_path(@assignment), notice: 'Role was successfully deleted.'
  end



    private
  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def set_duty
    @duty = @assignment.duties.find(params[:id])
  end

  def authorize_user
    redirect_to root_path, alert: 'You are not authorized to perform this action.' unless current_user_has_ta_privileges?
  end

  def redirect_to_create_page_and_show_error
    flash[:error] = @duty.errors.full_messages.join('. ')
    redirect_to action: :new, assignment_id: @assignment.id
  end

  def duty_params
    params.require(:duty).permit(:max_members_for_duty, :name)
  end
  end
