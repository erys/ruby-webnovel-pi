# frozen_string_literal: true

require 'jjwxc_ttf'

# class representing progress of character replacement in a chapter
class CorruptCharacterList
  include ActiveModel::API

  # @return [Array<CorruptCharacter>]
  attr_accessor :all_characters
  attr_accessor :index

  delegate :each, :map, :length, :index_by, to: :@all_characters

  def initialize(attributes = nil)
    super
    @index ||= 0
  end

  # @param original_chapter_id [Integer]
  # @param glyphs [Hash{String=>String}]
  def find_glyphs(original_chapter_id, glyphs)
    og_chapter = OriginalChapter.find(original_chapter_id)
    return unless og_chapter.font_file.attached?

    ttf = JjwxcTtf.from_string(og_chapter.font_file.download)
    all_characters.each do |corrupt_char|
      corrupt_char.glyph_md5 = ttf.md5_glyph(corrupt_char.og_bytes)
      Rails.logger.info("bytes: #{corrupt_char.og_bytes.codepoints[0]}, glyph: #{corrupt_char.glyph_md5}")
      corrupt_char.likely_replacement = glyphs[corrupt_char.glyph_md5]
    end
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def progress_percent
    (index * 100.0) / all_characters.length
  end

  def char_to_replace
    all_characters[index]
  end

  def next_char
    index < all_characters.length - 1 ? all_characters[index + 1] : nil
  end

  def prev_char
    index.positive? ? all_characters[index - 1] : nil
  end

  def can_undo?
    index.positive?
  end

  def done?
    index == all_characters.length
  end

  def undo
    previous = prev_char
    return if previous.blank?

    prev_replacement = previous.reset_char
    @index -= 1
    prev_replacement
  end

  def replace(correct_char)
    @all_characters[@index].correct_char = correct_char
    @index += 1
  end
end
