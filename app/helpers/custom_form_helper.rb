module CustomFormHelper
  def nice_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options.merge! builder: NiceFormBuilder
    form_with model: model, scope: scope, url: url, format: format, **options, &block
  end
end
