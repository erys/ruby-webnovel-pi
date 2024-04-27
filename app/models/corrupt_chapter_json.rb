# frozen_string_literal: true

# Version of corrupt chapter than can be serialized to/from json
class CorruptChapterJson < CorruptChapter
  include ActiveModel::Serializers::JSON

  JSON_SYMBOLS = %i[
    book_id
    ch_number
    possible_replacements
    possible_chars
    corrupt_chars_json
    corrupt_chars_index
    parsed
    id
    subtitle
    parts_json
  ].freeze

  attr_accessor :corrupt_chars_json, :corrupt_chars_index, :parts_json

  def attributes
    JSON_SYMBOLS.to_h do |symbol|
      [symbol.to_s, nil]
    end
  end

  def to_json(*_args)
    @corrupt_chars_json = corrupt_chars&.map(&:serializable_hash)
    @corrupt_chars_index = corrupt_chars&.index
    @parts_json = parts.to_json
    super
  end

  class << self
    def from_json(json_string)
      chap = new.from_json(json_string)
      chap.parts = CorruptChapterParts.new(chap.parts_json)
      chap.corrupt_chars = CorruptCharacterList.new(
        all_characters: chap.corrupt_chars_json&.map { |hash| CorruptCharacter.new(hash) },
        index: chap.corrupt_chars_index,
      )
      chap
    end
  end
end
