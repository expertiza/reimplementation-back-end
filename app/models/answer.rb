# frozen_string_literal: true

class Answer < ApplicationRecord
    extend ImportableExportableHelper
    mandatory_fields :answer, :comments
    hidden_fields :id, :created_at, :updated_at
    external_classes ExternalClass.new(Item, true, false, :txt),
                    ExternalClass.new(Response, true, false, :additional_comment)

    filter nil
    belongs_to :response
    belongs_to :item
end
