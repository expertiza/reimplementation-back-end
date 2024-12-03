class ChoiceRenderingStrategy
    def render_choices(item)
      raise NotImplementedError, 'This method should be overridden in subclasses'
    end
  end
  