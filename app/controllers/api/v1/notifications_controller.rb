class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show update destroy toggle_notification_visibility]
  before_action :authorize_user, only: %i[create update destroy toggle_notification_visibility]

  # GET /notifications
  def index
    # Filters for active, unread, and course_id if provided
    @notifications = Notification.all

    # Apply filters based on query parameters
    if params[:is_active].present?
      @notifications = @notifications.where(active_flag: params[:is_active] == 'true')
    end

    if params[:is_unread].present? && current_user
      @notifications = @notifications.joins(:user_notifications)
                                     .where(user_notifications: { user_id: current_user.id, read: false })
    end

    if params[:course_id].present?
      @notifications = @notifications.where(course_id: params[:course_id])
    end

    # Authorization: students can only view notifications for courses they're enrolled in
    @notifications = @notifications.where(course_id: current_user.enrolled_courses.pluck(:id)) if current_user.student?

    render json: @notifications
  end

  # GET /notifications/1
  def show
    # Ensure the user is either enrolled in the course or is the creator of the notification
    if authorized_user?
      render json: @notification
    else
      render json: { error: "You are not authorized to view this notification." }, status: :forbidden
    end
  end

  # POST /notifications
  def create
    @notification = Notification.new(notification_params)
    @notification.user_id = current_user.id

    if @notification.save
      render json: @notification, status: :created, location: @notification
    else
      render json: @notification.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /notifications/1
  def update
    if @notification.update(notification_params)
      render json: @notification
    else
      render json: @notification.errors, status: :unprocessable_entity
    end
  end

  # DELETE /notifications/1
  def destroy
    @notification.destroy
    head :no_content
  end

  # PATCH /notifications/1/toggle
  def toggle_notification_visibility
    if @notification.update(active_flag: !@notification.active_flag)
      render json: @notification
    else
      render json: { error: 'Unable to toggle notification visibility' }, status: :unprocessable_entity
    end
  end

  private

  # Set the notification for the current action
  def set_notification
    @notification = Notification.find(params[:id])
  end

  # Permit the required parameters for a notification
  def notification_params
    params.require(:notification).permit(:subject, :description, :expiration_date, :active_flag, :course_id)
  end

  # Ensure the user is authorized (only TA or instructor can create or update notifications)
  def authorize_user
    unless current_user&.can_manage_notifications?
      render json: { error: "You are not authorized to perform this action." }, status: :forbidden
    end
  end

  # Check if the user is authorized to view the notification
  def authorized_user?
    current_user.enrolled_courses.exists?(id: @notification.course_id) || current_user.id == @notification.user_id
  end
end
