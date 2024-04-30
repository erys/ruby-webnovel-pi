# frozen_string_literal: true

# == Schema Information
#
# Table name: characters
#
#  id                 :bigint           not null, primary key
#  character          :string(1)        not null
#  global_occurrences :integer
#  glyph_md5          :string
#  master_freq        :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_characters_on_character  (character) UNIQUE
#  index_characters_on_glyph_md5  (glyph_md5) UNIQUE
#
class Character < ApplicationRecord
  has_many :character_occurrences, dependent: :destroy
end
