# frozen_string_literal: true

class Node < ApplicationRecord
  belongs_to :parent, class_name: 'Node', foreign_key: 'parent_id', optional: true, inverse_of: false
  has_many :children, class_name: 'Node', foreign_key: 'parent_id', dependent: :nullify, inverse_of: false
end
