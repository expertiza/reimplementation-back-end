# frozen_string_literal: true
require 'response_service'
class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false
  
  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map
  
  

end


