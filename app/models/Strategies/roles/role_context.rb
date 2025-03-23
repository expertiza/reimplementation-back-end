# A Context class that is able to execute role strategy methods from clients
class RoleContext

  attr_reader :strategy

  #
  def validate_permissions
    raise NotImplementedError
  end

  def get_permissions
    @strategy.get_permissions
  end

  def set_strategy(RoleStrategy strategy)
    @strategy = strategy
  end

end
