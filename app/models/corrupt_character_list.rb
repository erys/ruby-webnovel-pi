# frozen_string_literal: true

# class representing progress of character replacement in a chapter
class CorruptCharacterList
  include ActiveModel::API
  attr_accessor :all_characters, :index

  delegate :each, :map, :length, to: :@all_characters

  def initialize(attributes = nil)
    super
    @index ||= 0
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
    return unless previous.present?

    prev_replacement = previous.reset_char
    @index -= 1
    prev_replacement
  end

  def replace(correct_char)
    @all_characters[@index].correct_char = correct_char
    @index += 1
  end
end
