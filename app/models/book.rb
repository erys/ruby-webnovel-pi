# frozen_string_literal: true

# == Schema Information
#
# Table name: books
#
#  id             :bigint           not null, primary key
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
#  jjwxc_id       :integer
#
# Indexes
#
#  index_books_on_author_id   (author_id)
#  index_books_on_short_name  (short_name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => authors.id)
#
class Book < ApplicationRecord
  include Comparable

  belongs_to :author
  has_many :chapters, dependent: :destroy
  has_many :character_occurrences, dependent: :destroy

  after_create :create_occurrences

  # TODO: #16 links to jjwxc
  def to_param
    short_name
  end

  def author_cn_name
    author&.og_name
  end

  def jjwxc_url
    "https://www.jjwxc.net/onebook.php?novelid=#{jjwxc_id}" if jjwxc_id.present?
  end

  def latest_chapter
    @latest_chapter ||= chapters.max { |a, b| a.ch_number <=> b.ch_number }
  end

  def new_chapter_number
    (latest_chapter&.ch_number || 0) + 1
  end

  def sortable_title
    tl_title.gsub(/^(A|An|The) /i, '')
  end

  def <=>(other)
    sortable_title.casecmp(other.sortable_title)
  end

  private

  def create_occurrences
    Character.all.each do |character|
      CharacterOccurrence.create(book: self, character:, occurrences: 0)
    end
  end
end
