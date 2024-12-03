class ScaleRenderingStrategy < ChoiceRenderingStrategy
    def render_choices(item)
      (1..item.scale).each do |number|
        puts number
      end
    end
  end
  