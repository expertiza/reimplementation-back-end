class ResponseSerializer < ActiveModel::Serializer
  attributes :id, :map_id, :additional_comment, :is_submitted, :created_at, :updated_at, :version_num, :round, :visibility
  has_one :response_map
end
