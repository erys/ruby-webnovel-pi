# == Schema Information
#
# Table name: character_occurrences
#
#  id           :bigint           not null, primary key
#  occurrences  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  book_id      :integer          not null
#  character_id :integer          not null
#
# Indexes
#
#  index_character_occurrences_on_book_id  (book_id)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#  fk_rails_...  (character_id => characters.id)
#
class CharacterOccurrence < ApplicationRecord
  include Comparable

  belongs_to :character
  belongs_to :book

  def <=> other
    comp_array <=> other.comp_array
  end

  def comp_array
    [occurrences, character.global_occurrences, -1 * character.master_freq]
  end
end
