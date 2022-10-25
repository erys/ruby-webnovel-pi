module CopyPasteHelper
  def paste_button(target, text: 'Paste', classes: [], tag_name: :div)
    classes = classes.union(%w(paste-btn btn))
    if tag_name == :div
      tag.div text, class: classes, 'paste-target': target
    elsif tag_name == :button
      tag.button text, class: classes, 'paste-target': target, type: 'button'
    else
      tag.send(tag_name, text, class: classes, 'paste-target': target)
    end
  end

  def copy_button(target, text: 'Copy', classes: [], tag_name: :div)
    classes = classes.union(%w(btn clipboard-btn))
    data_attrs = {'data-clipboard-action': 'copy', 'data-clipboard-target': target}
    if tag_name == :div
      tag.div text, class: classes, **data_attrs
    elsif tag_name == :button
      tag.button text, class: classes, **data_attrs, type: 'button'
    else
      tag.send(tag_name, text, class: classes, **data_attrs)
    end
  end

  def copy_paste_group(target, btn_classes: [])
    content = copy_button(target, classes: btn_classes.union(%w(btn-info))) +
      paste_button(target, classes: btn_classes.union(%w(btn-secondary)))
    tag.div content, class: %w(btn-group), role: :group
  end
end