# frozen_string_literal: true

# Books Helpers
module BooksHelper
  def book_list_tab(name, selected: false)
    tag.li book_list_tab_inner(name, selected:), class: 'nav-item', role: 'presentation'
  end

  def book_list_tab_inner(name, selected: false)
    classes = %w[nav-link]
    classes.push('active') if selected
    tag.button name.titleize,
               class: classes,
               id: "#{name.parameterize}-tab", type: 'button', role: 'tab',
               data: { 'bs-target': "##{name.parameterize}", 'bs-toggle': 'tab' },
               aria: { controls: name.parameterize, selected: selected.to_s }
  end

  def book_list_tab_pane(name, selected: false, &block)
    classes = %w[tab-pane fade]
    classes.push('show', 'active') if selected
    tag.div class: classes, id: name.parameterize, role: 'tabpanel',
            aria: { labelledby: "#{name.parameterize}-tab" }, &block
  end
end
