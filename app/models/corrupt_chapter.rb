# frozen_string_literal: true

# Model representing JJWXC vip chapter that contains corrupted characters
class CorruptChapter
  include ActiveModel::API

  COMPOSE_CHAR = "\u200c"

  # @return [Integer]
  attr_accessor :book_id
  # @return [Integer]
  attr_accessor :original_chapter_id
  # @return [Integer]
  attr_accessor :ch_number
  # @return [CorruptCharacterList]
  attr_accessor :corrupt_chars
  # @return [Array<String>]
  attr_accessor :possible_replacements
  # @return [Hash{String=>Array<Integer>}]
  attr_accessor :possible_chars
  # @return [Boolean]
  attr_accessor :parsed
  # @return [String]
  attr_accessor :id
  # @return [String]
  attr_accessor :subtitle

  attr_internal

  delegate :can_undo?, :char_to_replace, :prev_char, :next_char, :done?, :progress_percent, to: :corrupt_chars
  delegate :title, :main_text, :substitutions, :footnote, :chapter_text, :display_text, to: :parts

  def initialize(attributes, parts_params:)
    super(attributes)
    @parts = CorruptChapterParts.new(parts_params)
    @id = SecureRandom.uuid
  end

  def persisted?
    main_text.present? && book_id.present?
  end

  def percent
    ((char_to_replace.first_occurrence * 100.0) / main_text.length).round
  end

  def parse_main_text(corrupt_hash)
    main_text.chars.each_with_index { |char, index| log_occurrence(corrupt_hash, index, char) }
  end

  def parse
    return if @parsed
    raise 'og_text and book_id must be defined for parsing' unless persisted?

    init_occurrences
    corrupt_hash = {}
    parse_main_text(corrupt_hash)
    @corrupt_chars = CorruptCharacterList.new(all_characters: corrupt_hash.values.sort.reverse!)
    @possible_replacements = @possible_chars.select { |_, value| (value[1]).zero? }.keys
    @parsed = true
  end

  def replace(new_char)
    @corrupt_chars.replace(new_char)
    @possible_replacements.delete(new_char)
  end

  def undo
    previous_replacement = @corrupt_chars.undo
    return unless previous_replacement

    @possible_replacements.push(previous_replacement)
    @possible_replacements = @possible_chars.keys.intersection(@possible_replacements)
    previous_replacement
  end

  def next_bytes
    @corrupt_chars.next_char&.og_bytes || 'DONE'
  end

  def init_chapter
    finalize_text
    register_occurrences
    chapter = Chapter.new(book_id:, ch_number:, og_subtitle: subtitle,
                          og_title: title)
    chapter.og_text_data = chapter_text
    chapter
  end

  def register_occurrences
    id_hash = possible_chars.values.to_h
    book = Book.includes(:character_occurrences).find(book_id)
    book.character_occurrences.each do |occurrence|
      count = id_hash[occurrence.id]
      unless count.zero?
        occurrence.increment(:occurrences, count)
        occurrence.save!
      end
      # this field is only used the first time you clean a chapter for a book
      # so removing for performance reasons
      # occurrence.character.global_occurrences += id_hash[occurrence.id]
      # occurrence.character.save
    end
  end

  private

  # @return [CorruptChapterParts]
  attr_accessor :parts

  def log_occurrence(corrupt_hash, index, char)
    if char == COMPOSE_CHAR
      char = main_text[index - 1, 2]
      if corrupt_hash.key?(char)
        corrupt_hash[char].add_occurrence
      else
        corrupt_hash[char] = CorruptCharacter.new({ og_bytes: char, first_occurrence: index })
      end
    elsif @possible_chars.key?(char)
      @possible_chars[char][1] += 1
    end
  end

  def init_occurrences
    book = Book.includes(character_occurrences: :character).find(book_id)
    book_occurrences = book.character_occurrences.sort.reverse!
    @possible_chars = book_occurrences.to_h { |occurrence| [occurrence.character.character, [occurrence.id, 0]] }
  end

  def finalize_text
    @corrupt_chars.each do |char|
      char.replace(main_text)
      possible_chars[char.correct_char][1] = char.occurrences
    end
  end
end
