class MultipleChoiceRenderingStrategy < ChoiceRenderingStrategy
    def render_choices(item)
      item.choices.each do |choice|
        puts choice
      end
    end
  end
  