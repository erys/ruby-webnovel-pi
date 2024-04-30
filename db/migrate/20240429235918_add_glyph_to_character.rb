# frozen_string_literal: true

class AddGlyphToCharacter < ActiveRecord::Migration[7.0]
  def change
    add_column :characters, :glyph_md5, :string
    add_index :characters, :glyph_md5, unique: true
  end
end
