class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show edit update destroy]
  helper_method :validate_params

  include AuthorizationHelper

  # Give permission to manage notifications to appropriate roles
  def action_allowed?
    current_user_has_ta_privileges?
  end

  # Handle cases where a student tries to access this controller
  def run_get_notification
    redirect_to(controller: :student_task, action: :view) if current_user_has_student_privileges?
  end

  # GET /notifications
  def index
    # If the user is an Instructor or TA, show all notifications they created
    if current_user_has_ta_privileges? || current_user_has_instructor_privileges?
      @notifications = Notification.where(user_id: session[:user].id)
    elsif current_user_has_student_privileges?
      # If the user is a student, show only notifications for their courses
      course_ids = session[:user].courses.pluck(:id)
      @notifications = Notification.where(course_id: course_ids, active_flag: true)
    else
      @notifications = []
    end
    render :list
  end

  # GET /notifications/1
  def show
    # Ensure the notification is accessible to the current user
    if notification_accessible?(@notification)
      render :show
    else
      flash[:error] = "You do not have access to this notification."
      redirect_to notifications_path
    end
  end

  # GET /notifications/new
  def new
    @notification = Notification.new
  end

  # GET /notifications/1/edit
  def edit
    unless notification_accessible?(@notification)
      flash[:error] = "You are not authorized to edit this notification."
      redirect_to notifications_path
    end
  end

  # POST /notifications
  def create
    @notification = Notification.new(notification_params)
    @notification.user_id = session[:user].id

    if @notification.save
      flash[:success] = "Notification was successfully created."
      redirect_to @notification
    else
      flash[:error] = @notification.errors.full_messages.to_sentence
      render :new
    end
  end

  # PATCH/PUT /notifications/1
  def update
    if notification_accessible?(@notification) && @notification.update(notification_params)
      flash[:success] = "Notification was successfully updated."
      redirect_to @notification
    else
      flash[:error] = "You are not authorized to update this notification."
      render :edit
    end
  end

  # DELETE /notifications/1
  def destroy
    if notification_accessible?(@notification)
      @notification.destroy
      flash[:success] = "Notification was successfully deleted."
    else
      flash[:error] = "You are not authorized to delete this notification."
    end
    redirect_to notifications_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Notification not found."
    redirect_to notifications_path
  end

  # Define strong parameters for notification creation/update
  def notification_params
    params.require(:notification).permit(:course_id, :subject, :description, :expiration_date, :active_flag)
  end

  # Helper method to check if a notification is accessible to the current user
  def notification_accessible?(notification)
    # Instructors and TAs can access their own notifications
    return true if notification.user_id == session[:user].id

    # Students can access notifications for their courses
    return true if current_user_has_student_privileges? &&
                   session[:user].courses.exists?(id: notification.course_id)

    false
  end
end
