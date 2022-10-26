# frozen_string_literal: true

# Model representing corrupted character in JJWXC VIP chapter
class CorruptCharacter
  include Comparable
  include ActiveModel::API
  include ActiveModel::Serializers::JSON
  CHAR_ATTR = %i[
    og_bytes
    occurrences
    correct_char
    first_occurrence
  ].freeze
  attr_accessor(*CHAR_ATTR)

  def initialize(attributes = nil)
    super
    @occurrences ||= 1
  end

  def replace(og_text)
    og_text.gsub!(og_bytes, correct_char)
  end

  def reset_char
    bad_char = correct_char
    @correct_char = nil
    bad_char
  end

  def attributes
    CHAR_ATTR.map { |symbol| [symbol.to_s, nil] }.to_h
  end

  def known?
    @correct_char.present?
  end

  def add_occurrence
    @occurrences += 1
  end

  def highlight(excerpt, cur_char)
    if known?
      excerpt.gsub!(og_bytes, "<span class=\"text-info\">#{@correct_char}</span>")
    elsif self == cur_char
      excerpt.gsub!(og_bytes, '<strong class="text-danger">XXX</strong>')
    else
      excerpt.gsub!(og_bytes, '<em class="text-secondary">xxx</em>')
    end
  end

  def <=>(other)
    [occurrences, -first_occurrence] <=> [other.occurrences, -other.first_occurrence]
  end
end
