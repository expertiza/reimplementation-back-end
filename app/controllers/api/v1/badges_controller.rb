class Api::V1::BadgesController < ApplicationController
  before_action :set_badge, only: [:show, :edit, :update, :destroy]
  before_action :set_return_to, only: [:new]

  def index
    @badges = Badge.all
    render json: { badges: @badges }, status: :ok
  end

  def new
    @badge = Badge.new
    render json: { badge: @badge }, status: :ok
  end

  def show
    render json: { badge: @badge }, status: :ok
  end

  def create
    @badge = Badge.new(badge_params)

    if @badge.save
      render json: { badge: @badge }, status: :created
    else
      render json: { errors: @badge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @badge.update(badge_params)
      render json: { badge: @badge }, status: :ok
    else
      render json: { errors: @badge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @badge.destroy
    render json: { message: "Badge was successfully destroyed." }, status: :ok
  end

  private

  def set_badge
    @badge = Badge.find(params[:id])
  end


  def set_return_to
    session[:return_to] ||= request.referer
  end

  def badge_params
    params.require(:badge).permit(:name, :description, :image_name, :image_file)
  end
end
