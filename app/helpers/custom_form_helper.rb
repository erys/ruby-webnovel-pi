# frozen_string_literal: true

# Form helpers
module CustomFormHelper
  def nice_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options.merge! builder: NiceFormBuilder
    form_with model:, scope:, url:, format:, **options, &block
  end
end
