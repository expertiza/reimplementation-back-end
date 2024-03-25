# frozen_string_literal: true

class Response < ApplicationRecord
  belongs_to :response_map
  belongs_to :question
end
