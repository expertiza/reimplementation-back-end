class Api::V1::BadgesController < ApplicationController

  before_action :set_badge, only: [:show, :edit, :update, :destroy]
  before_action :set_return_to, only: [:new]

  def action_allowed?
    current_user_has_ta_privileges?
  end

  def index
    @badges = Badge.all
  end

  def new
    @badge = Badge.new
  end

  def create
    @badge = Badge.new(badge_params)

    if @badge.save
      redirect_to redirect_to_url, notice: 'Badge was successfully created'
    else
      render :new
    end
  end

  def update
    if @badge.update(badge_params)
      redirect_to @badge, notice: 'Badge was successfully updated.'
    else
      render :edit
    end
  end

  private

  def set_badge
    @badge = Badge.find(params[:id])
  end

  def set_return_to
    session[:return_to] ||= request.referer
  end

  def redirect_to_url
    session.delete(:return_to) || badges_url
  end

  def badge_params
    params.require(:badge).permit(:name, :description, :image_name, :image_file)
  end
end
