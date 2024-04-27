# frozen_string_literal: true

# object storing chapter components
class CorruptChapterParts
  include ActiveModel::API
  include ActiveModel::Serializers::JSON

  # @return [String]
  attr_accessor :title
  # @return [String]
  attr_accessor :main_text
  # @return [Array<String>]
  attr_accessor :substitutions
  # @return [String, NilClass]
  attr_accessor :footnote

  SUBSTITUTION_STRING = 'SUBSTITUTE_ME_%d'

  # @param [Hash] attributes
  # @option attributes [String] :og_text Full chapter text for use with copy/paste method
  # @option attributes [String] :title Title of chapter
  # @option attributes [String] :main_text Main text of chapter containing corrupt characters
  # @option attributes [String] :footnote Author's note
  # @option attributes [Array<String>] :substitutions Uncorrupted text that is stored in ::before or ::after css
  def initialize(attributes = {})
    og_text = attributes.delete(:og_text)
    super
    # for copy/paste creation
    if og_text.present?
      parse_og_text(og_text)
    else
      main_text.gsub!(JJWXC_TEXT, '') if main_text.present?
      footnote.gsub!(ACK_REGEX, "\\1\n[truncated]\n#{ACK_END}") if footnote.present?
    end
  end

  CHAPTER_END_STR = '插入书签'
  JJWXC_TEXT = '@无限好文，尽在晋江文学城'

  # constants for the acknowledgements section in the author's note
  ACK_END = '非常感谢大家对我的支持，我会继续努力的！'
  ACK_REGEX = /(感谢在\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}~\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}期间为我投出霸王票或灌溉营养液的小天使哦~)
                .*
                #{ACK_END}/mx
  # @param og_text [String]
  def parse_og_text(og_text)
    og_text.gsub!(JJWXC_TEXT, '')
    og_text.gsub!(ACK_REGEX, "\\1\n[truncated]\n#{ACK_END}")
    ch_start = og_text.index("\n") || 0
    ch_end = og_text.index(CHAPTER_END_STR) || og_text.length
    @main_text = og_text[ch_start...ch_end]&.strip
    @title = og_text.lines.first&.strip&.force_encoding('utf-8')
    @footnote = og_text[ch_end, og_text.length]&.strip
  end

  # @return [String]
  def display_text
    return main_text if substitutions.blank?

    new_text = main_text

    substitutions.each_with_index do |value, key|
      new_text = new_text.gsub(SUBSTITUTION_STRING % key, value)
    end

    new_text
  end

  # @return [String]
  def chapter_text
    [display_text, @footnote].compact_blank.join("\n\n")
  end
end
