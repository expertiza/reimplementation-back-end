class ApplicationController < ActionController::API
  include JwtToken

  def find_resource_by_id(model, id)
    model.find(id)
  rescue ActiveRecord::RecordNotFound
    render_error("#{model.name} not found", :not_found)
    nil
  end

  def render_success(data, status = :ok)
    render json: data, status: status
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end