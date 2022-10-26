# frozen_string_literal: true

# Version of corrupt chapter than can be serialized to/from json
class CorruptChapterJson < CorruptChapter
  include ActiveModel::Serializers::JSON

  JSON_SYMBOLS = %i[
    og_text
    book_id
    ch_number
    possible_replacements
    possible_chars
    corrupt_chars_json
    parsed
    id
    subtitle
  ].freeze

  attr_accessor :corrupt_chars_json

  def attributes
    JSON_SYMBOLS.map do |symbol|
      [symbol.to_s, nil]
    end.to_h
  end

  def to_json(*_args)
    @corrupt_chars_json = corrupt_chars.map(&:serializable_hash)
    super
  end

  class << self
    def from_json(json_string)
      chap = new.from_json(json_string)
      chap.corrupt_chars = chap.corrupt_chars_json&.map { |hash| CorruptCharacter.new(hash) }
      chap
    end
  end
end
