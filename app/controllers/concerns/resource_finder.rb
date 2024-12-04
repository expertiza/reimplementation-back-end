module ResourceFinder
  extend ActiveSupport::Concern

  included do

    # Find a specific resource by ID, handling the case where it's not found
    def find_resource_by_id(resource, id)
      resource.find(id)
    rescue ActiveRecord::RecordNotFound
      render_error("#{resource.name} not found", :not_found)
      nil
    end
  end
end