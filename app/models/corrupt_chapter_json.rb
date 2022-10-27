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
    corrupt_chars_index
    parsed
    id
    subtitle
  ].freeze

  attr_accessor :corrupt_chars_json, :corrupt_chars_index

  def attributes
    JSON_SYMBOLS.map do |symbol|
      [symbol.to_s, nil]
    end.to_h
  end

  def to_json(*_args)
    @corrupt_chars_json = corrupt_chars&.map(&:serializable_hash)
    @index = corrupt_chars.index
    super
  end

  class << self
    def from_json(json_string)
      chap = new.from_json(json_string)
      chap.corrupt_chars = CorruptCharacterList.new(
        all_characters: chap.corrupt_chars_json&.map { |hash| CorruptCharacter.new(hash) },
        index: chap.corrupt_chars_index
      )
      chap
    end
  end
end
