class Response < ApplicationRecord
  include ScoreHelper

  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false
end