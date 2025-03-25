class FindResourceService
  def self.call(model, id)
    model.find(id)
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound.new("#{model.name} not found")
  end
end