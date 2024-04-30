# frozen_string_literal: true

require 'ttf'

# for parsing jjwxc font ttf files
class JjwxcTtf
  attr_reader :cmap, :glyph_data, :ttf, :character_mapping, :glyphs, :num_glyphs, :glyph_offsets

  def initialize(filename)
    @filename = filename
    @ttf = Ttf.from_file(filename)

    parse
  end

  def parse
    @cmap = get_table('cmap')
    @num_glyphs = get_table('maxp').num_glyphs
    @glyph_data = get_table('glyf', raw: true)
    loca = get_table('loca')
    @glyph_offsets = loca.unpack("S>#{@num_glyphs + 1}")

    @character_mapping = @cmap.tables.find { |table| table.platform_id == 0 && table.encoding_id == 3 }.table.value
  end

  def get_table(tag, raw: false)
    table = @ttf.directory_table.find { |t| t.tag == tag }
    if raw
      table.value
      table._raw_value
    else
      table.value
    end
  end

  def md5_glyph(char)
    Digest::MD5.hexdigest(find_glyph(char))
  end

  def find_character(corrupt)
    Character.find_by(glyph_md5: md5_glyph(corrupt))
  end

  def update_glyph(character, corrupt)
    Character.find_by(character:).update!(glyph_md5: md5_glyph(corrupt))
  end

  def get_glyph(index)
    offset = @glyph_offsets[index]
    length = @glyph_offsets[index + 1] - offset

    @glyph_data[offset * 2, length]
  end

  def find_glyph(char)
    index = glyph_index(char)

    get_glyph(index)
  end

  def glyph_index(char)
    char_val = char.codepoints[0]
    index = @character_mapping.end_count.find_index { |end_count| end_count >= char_val }
    start_code = @character_mapping.start_count[index]
    return 0 if start_code > char_val

    id_range_offset = @character_mapping.id_range_offset[index]

    id_index = (id_range_offset / 2) - @character_mapping.seg_count + index + char_val - start_code
    @character_mapping.glyph_id_array[id_index]
  end

  def inspect
    { filename: @filename, num_glyphs: }.inspect
  end
end
