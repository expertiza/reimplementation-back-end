# frozen_string_literal: true

class Answer < ApplicationRecord
    extend ImportableExportableHelper
    mandatory_fields :answer, :comments
    external_classes ExternalClass.new(Item, true, false, :txt),
                    ExternalClass.new(Response, true, false, :additional_comment)

    belongs_to :response
    belongs_to :item
end
