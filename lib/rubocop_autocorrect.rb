# frozen_string_literal: true

RuboCop::Cop::Team.class_eval do
  def autocorrect(processed_source, report, original:, offset:)
    @updated_source_file = false
    return unless autocorrect?
    return if report.processed_source.parser_error

    new_source = autocorrect_report(report, original:, offset:)

    return unless new_source

    if @options[:stdin]
      # holds source read in from stdin, when --stdin option is used
      @options[:stdin] = new_source
    else
      filename = processed_source.file_path
      File.write(filename, new_source, mode: 'wb')
    end
    @updated_source_file = true
  end
end
