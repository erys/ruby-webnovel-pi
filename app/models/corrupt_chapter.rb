# frozen_string_literal: true

# Model representing JJWXC vip chapter that contains corrupted characters
class CorruptChapter
  include ActiveModel::API

  COMPOSE_CHAR = "\u200c"
  CHAPTER_END_STR = '插入书签'
  JJWXC_TEXT = '@无限好文，尽在晋江文学城'

  attr_accessor :og_text, :book_id, :ch_number, :corrupt_chars, :possible_replacements, :possible_chars,
                :parsed, :id, :subtitle

  delegate :can_undo?, :char_to_replace, :prev_char, :next_char, :done?, to: :@corrupt_chars

  def initialize(attributes = nil)
    super
    @id = SecureRandom.uuid
  end

  def persisted?
    og_text.present? && book_id.present?
  end

  def percent
    ((char_to_replace.first_occurrence * 100.0) / og_text.length).round
  end

  def parse
    return if @parsed
    raise 'og_text and book_id must be defined for parsing' unless persisted?

    initialize_text
    corrupt_hash = {}
    (@ch_start...@ch_end).each { |index| log_occurrence(corrupt_hash, index, og_text[index]) }
    @corrupt_chars = CorruptCharacterList.new(
      all_characters: corrupt_hash.values.sort.reverse!
    )
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
                          og_title: og_text.lines.first.strip.force_encoding('utf-8'))
    chapter.og_text_data = og_text
    chapter
  end

  def register_occurrences
    id_hash = possible_chars.values.to_h
    book = Book.includes(:character_occurrences).find(book_id)
    book.character_occurrences.each do |occurrence|
      count = id_hash[occurrence.id]
      occurrence.increment!(:occurrences, count) unless count.zero?
      # this field is only used the first time you clean a chapter for a book
      # so removing for performance reasons
      # occurrence.character.global_occurrences += id_hash[occurrence.id]
      # occurrence.character.save
    end
  end

  private

  def log_occurrence(corrupt_hash, index, char)
    if char == COMPOSE_CHAR
      char = @og_text[index - 1, 2]
      if corrupt_hash.key?(char)
        corrupt_hash[char].add_occurrence
      else
        corrupt_hash[char] = CorruptCharacter.new({ og_bytes: char, first_occurrence: index })
      end
    elsif @possible_chars.key?(char)
      @possible_chars[char][1] += 1
    end
  end

  def initialize_text
    @og_text.gsub!(JJWXC_TEXT, '')
    @ch_start = @og_text.index("\n") || 0
    @ch_end = @og_text.index(CHAPTER_END_STR) || @og_text.length
    init_occurrences
  end

  def init_occurrences
    book = Book.includes(character_occurrences: :character).find(book_id)
    book_occurrences = book.character_occurrences.sort.reverse!
    @possible_chars = book_occurrences.map { |occurrence| [occurrence.character.character, [occurrence.id, 0]] }.to_h
  end

  def finalize_text
    @corrupt_chars.each do |char|
      char.replace(og_text)
      possible_chars[char.correct_char][1] = char.occurrences
    end
  end
end
