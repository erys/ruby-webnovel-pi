# frozen_string_literal: true

# Model representing JJWXC vip chapter that contains corrupted characters
class CorruptChapter
  include ActiveModel::API

  COMPOSE_CHAR = "\u200c"
  CHAPTER_END_STR = '插入书签'
  JJWXC_TEXT = '@无限好文，尽在晋江文学城'

  attr_accessor :og_text, :book_id, :ch_number, :corrupt_chars, :possible_replacements, :possible_chars,
                :parsed, :id, :subtitle

  def initialize(attributes = nil)
    super
    @id = SecureRandom.uuid
    @corrupt_chars ||= []
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
    @corrupt_chars = corrupt_hash.values.sort.reverse!
    @possible_replacements = @possible_chars.select { |_, value| (value[1]).zero? }.keys
    @parsed = true
  end

  def replace(new_char)
    char_to_replace.correct_char = new_char
    @possible_replacements.delete(new_char)
  end

  def can_undo?
    @corrupt_chars.first&.known?
  end

  def prev_char
    return nil unless can_undo?
    return @corrupt_chars.last if char_to_replace.nil?

    @corrupt_chars[@corrupt_chars.index(char_to_replace) - 1]
  end

  def undo
    previous = prev_char
    return unless previous.present?

    @possible_replacements.push(previous.correct_char)
    @possible_replacements = @possible_chars.keys.intersection(@possible_replacements)
    previous.reset_char
  end

  def char_to_replace
    @corrupt_chars.find { |char| !char.known? }
  end

  def next_bytes
    @corrupt_chars[@corrupt_chars.index(char_to_replace) + 1]&.og_bytes
  end

  def done?
    @corrupt_chars.all?(&:known?)
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
      occurrence.increment!(:occurrences, id_hash[occurrence.id]) unless (id_hash[occurrence.id]).zero?
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
    corrupt_chars.each do |char|
      char.replace(og_text)
      possible_chars[char.correct_char][1] = char.occurrences
    end
  end
end
