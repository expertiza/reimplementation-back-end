include ActionController::Flash

class Api::V1::CoursesController < ApplicationController
  before_action :set_course, only: %i[ show update destroy ]

  # GET /courses
  def index
    @courses = Course.all

    render json: @courses
  end

  # GET /courses/1
  def show
    render json: @course
  end

  # POST /courses
  def create
    @course = Course.new(course_params)

    if @course.save
      render json: @course, status: :created
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /courses/1
  def update
    if @course.update(course_params)
      render json: @course
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  # DELETE /courses/1
  def destroy
    @course.destroy
    render json: { message: "Course with id #{params[:id]}, deleted" }, status: :ok
  end

  # Adds a Teaching Assistant to the course
  def add_ta
    @course = Course.find(params[:id])
    @user = User.find_by(id: params[:ta_id])
    if @user.nil?
      return render json: { status: "error", message: "The user inputted " + params[:ta_id].to_s + " does not exist" }, status: :bad_request
    elsif !TaMapping.where(ta_id: @user.id, course_id: @course.id).empty?
      return render json: { status: "error", message: "The user inputted " + params[:ta_id].to_s + " is already a TA for this course." }, status: :bad_request
    else
      @ta_mapping = TaMapping.create(ta_id: @user.id, course_id: @course.id)
      @role_id = Role.find_by(name: 'Teaching Assistant').id
      @user.update_attribute(:role_id, @role_id)
      @user.save
    end

    if @ta_mapping.save
      render json: @ta_mapping.slice(:course_id, :ta_id), status: :created
    else
      render json: @ta_mapping.errors, status: :unprocessable_entity
    end
  end

  # Displays all Teaching Assistants for the course
  def view_tas
    @course = Course.find(params[:id])
    @ta_mappings = @course.ta_mappings
    @users = User.where(id: @ta_mappings.pluck(:ta_id))
    render json: @users, status: :ok
  end

  # Removes Teaching Assistant from the course
  def remove_ta
    @ta_mapping = TaMapping.find_by(course_id: params[:id], ta_id: params[:ta_id])
    if @ta_mapping.nil?
      return render json: { status: "error", message: "No TA mapping found for the specified course and TA" }, status: :not_found
    end
    @ta = User.find(@ta_mapping.ta_id)
    # if the user is not a TA for any other course, then the role should be changed to student
    other_ta_mappings_num = TaMapping.where(ta_id: params[:ta_id]).size - 1
    if other_ta_mappings_num.zero?
      @role_id = Role.find_by(name: 'Student').id
      @ta.update_attribute(:role_id, @role_id)
    end
    @ta_mapping.destroy
    render json: { message: "The TA " + @ta.name + " has been removed." }, status: :ok
  end

  # Creates a copy of the course
  def copy
    existing_course = Course.find(params[:id])
    @new_course = Course.new()
    @new_course = existing_course.dup
    @new_course.directory_path = @new_course.directory_path + '_copy'
    if @new_course.save
      render json: { message: "The course " + existing_course.name + " has been successfully copied" }
    else
      render json: { message: "The course was not able to be copied" }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def course_params
    params.require(:course).permit(:name, :directory_path, :info, :private, :instructor_id, :institution_id)
  end
end
