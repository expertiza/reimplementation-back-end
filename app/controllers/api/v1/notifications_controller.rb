class Api::V1::NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show update destroy]

  include AuthorizationHelper

  # Authorization to manage notifications
  def action_allowed?
    current_user_has_ta_privileges?
  end

  # GET /notifications
  def index
    if current_user_has_ta_privileges? || current_user_has_instructor_privileges?
      @notifications = Notification.where(user_id: session[:user].id)
    elsif current_user_has_student_privileges?
      course_ids = session[:user].courses.pluck(:id)
      @notifications = Notification.where(course_id: course_ids, active_flag: true)
    else
      @notifications = []
    end

    render json: @notifications, status: :ok
  end

  # GET /notifications/:id
  def show
    if notification_accessible?(@notification)
      render json: @notification, status: :ok
    else
      render json: { error: 'You do not have access to this notification.' }, status: :forbidden
    end
  end

  # POST /notifications
  def create
    @notification = Notification.new(notification_params)
    @notification.user_id = session[:user].id

    if @notification.save
      render json: @notification, status: :created
    else
      render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /notifications/:id
  def update
    if notification_accessible?(@notification) && @notification.update(notification_params)
      render json: @notification, status: :ok
    else
      render json: { error: 'You are not authorized to update this notification or invalid data provided.' }, status: :forbidden
    end
  end

  # DELETE /notifications/:id
  def destroy
    if notification_accessible?(@notification)
      @notification.destroy
      render json: { message: 'Notification was successfully deleted.' }, status: :ok
    else
      render json: { error: 'You are not authorized to delete this notification.' }, status: :forbidden
    end
  end

  # PATCH /notifications/:id/toggle_active
  def toggle_notification_visibility
    if notification_accessible?(@notification)
      @notification.update(active_flag: !@notification.active_flag)
      render json: { message: 'Notification visibility toggled successfully.', notification: @notification }, status: :ok
    else
      render json: { error: 'You are not authorized to toggle this notification.' }, status: :forbidden
    end
  end

  private

  # Set notification by ID
  def set_notification
    @notification = Notification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Notification not found.' }, status: :not_found
  end

  # Strong parameters for notification
  def notification_params
    params.require(:notification).permit(:course_id, :subject, :description, :expiration_date, :active_flag)
  end

  # Check if a notification is accessible by the current user
  def notification_accessible?(notification)
    # Instructors and TAs can access their own notifications
    return true if notification.user_id == session[:user].id

    # Students can access notifications for their enrolled courses
    return true if current_user_has_student_privileges? &&
                   session[:user].courses.exists?(id: notification.course_id)

    false
  end
end
