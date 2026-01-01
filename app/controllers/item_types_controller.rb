class ItemTypesController < ApplicationController
  # GET /item_types
  def index
    item_types = ItemType.all
    render json: item_types
  end
end
