# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  def index
    questionnaire = Questionnaire.find(params[:questionnaire_id])

    Rails.logger.info "Items for Questionnaire #{questionnaire.id}:"
    questionnaire.items.each do |item|
      Rails.logger.info item.attributes.inspect
    end

    items_json = questionnaire.items.as_json
    Rails.logger.info "JSON being rendered: #{items_json.inspect}"

    render json: items_json
  end
end
