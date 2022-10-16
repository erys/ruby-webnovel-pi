# == Schema Information
#
# Table name: books
#
#  id             :integer          not null, primary key
#  description    :text
#  og_source      :string
#  og_source_link :string
#  og_title       :string           not null
#  phonetic_title :string
#  short_name     :string
#  tl_source      :string
#  tl_source_link :string
#  tl_title       :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  author_id      :integer          not null
#
# Indexes
#
#  index_books_on_author_id   (author_id)
#  index_books_on_short_name  (short_name) UNIQUE
#
# Foreign Keys
#
#  author_id  (author_id => authors.id)
#
class Book < ApplicationRecord
  belongs_to :author
  has_many :chapters
  has_many :character_occurrences

  after_create :create_occurrences

  def to_param
    short_name
  end

  def author_cn_name
    author&.og_name
  end

  def latest_chapter
    @latest_chapter ||= self.chapters.max { |a, b| a.ch_number <=> b.ch_number }
  end

  def new_chapter_number
    (latest_chapter&.ch_number || 0) + 1
  end

  private
  
  def create_occurrences
    Character.all.each do |character|
      CharacterOccurrence.create(book: self, character: character, occurrences: 0)
    end
  end
end
