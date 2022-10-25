class NiceFormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Helpers::TagHelper
  def floating_label_text_field(attribute, title, field_options = {}, options = {})
    floating_label_field(:text_field, attribute, title, field_options, options)
  end

  def floating_label_number_field(attribute, title, field_options = {}, options = {})
    floating_label_field(:number_field, attribute, title, field_options, options)
  end
  def floating_label_text_area(attribute, title, field_options = {}, options = {})
    floating_label_field(:text_area, attribute, title, field_options, options)
  end

  def ch_number_field(options = {})
    floating_label_number_field :ch_number, "Chapter number", {step: 1}, options
  end

  def copy_paste_float_text_field(attribute, title, options)
    content = floating_label_text_field(attribute, title) +
      @template.copy_button(field_id(attribute), classes: %w(btn-info), tag_name: :button) +
      @template.paste_button(field_id(attribute), classes: %w(btn-secondary), tag_name: :button)
    tag.div content, **add_classes_to_options(options, %w(input-group))
  end

  private
  def floating_label_field(field_type, attribute, title, field_options = {}, options = {})
    field_options = add_classes_to_options(field_options, ['form-control']).merge(placeholder: 'placeholder')
    content = self.public_send(field_type, attribute, field_options) + label(attribute, title)
    tag.div content, **add_classes_to_options(options, ['form-floating'])
  end

  def add_classes_to_options(options = {}, classes = [])
    return {class: classes} if options.blank?
    if options[:class].present?
      old_classes = options[:class]
      if old_classes.kind_of?(Array)
        options[:class] = old_classes.union(classes)
      else
        options[:class] = classes.append(old_classes).join(' ')
      end
      options
    else
      options.merge(class: classes)
    end
  end

end
