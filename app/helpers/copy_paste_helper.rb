# frozen_string_literal: true

# Helpers for creating copy and paste buttons
module CopyPasteHelper
  def paste_button(target, text: 'Paste', classes: [], tag_name: :div, is_submit: false)
    classes = classes.union(%w[paste-btn btn])
    copy_or_paste_button(tag_name, text, classes, attrs: { 'paste-target': target }, is_submit:)
  end

  def copy_button(target, text: 'Copy', classes: [], tag_name: :div, is_submit: false)
    classes = classes.union(%w[btn clipboard-btn])
    data_attrs = { 'data-clipboard-action': 'copy', 'data-clipboard-target': target }
    copy_or_paste_button(tag_name, text, classes, attrs: data_attrs, is_submit:)
  end

  def copy_text_button(copy_text, label_text: 'Copy', classes: [], tag_name: :div, is_submit: false)
    classes = classes.union(%w[btn clipboard-btn])
    data_attrs = { 'data-clipboard-action': 'copy', 'data-clipboard-text': copy_text }
    copy_or_paste_button(tag_name, label_text, classes, attrs: data_attrs, is_submit:)
  end

  def copy_or_paste_button(tag_name, text, classes, is_submit: false, attrs: {})
    case tag_name
    when :div
      tag.div text, class: classes, **attrs
    when :button
      attrs = attrs.merge(type: 'button') unless is_submit
      tag.button text, class: classes, **attrs
    else
      tag.send(tag_name, text, class: classes, **attrs)
    end
  end

  def copy_paste_group(target, btn_classes: [])
    content = copy_button(target, classes: btn_classes.union(%w[btn-info])) +
              paste_button(target, classes: btn_classes.union(%w[btn-secondary]))
    tag.div content, class: %w[btn-group], role: :group
  end
end
