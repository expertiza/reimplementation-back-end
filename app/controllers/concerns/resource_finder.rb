module ResourceFinder
  extend ActiveSupport::Concern

  included do

    # Find a resource by its ID and handle the case where it is not found
    # @param resource [Class] the resource class to search
    # @param id [Integer] the ID of the resource
    # @return [Object, nil] the found resource or nil if not found
    def find_resource_by_id(resource, id)
      resource.find(id)
    rescue ActiveRecord::RecordNotFound
      render_error("#{resource.name} not found", :not_found)
      nil
    end
  end
end