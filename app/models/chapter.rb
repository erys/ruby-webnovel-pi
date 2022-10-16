# == Schema Information
#
# Table name: chapters
#
#  id         :bigint           not null, primary key
#  ch_number  :integer
#  og_title   :string
#  tl_title   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  book_id    :integer          not null
#
# Indexes
#
#  index_chapters_on_book_id                (book_id)
#  index_chapters_on_book_id_and_ch_number  (book_id,ch_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#

# using https://mikerogers.io/2019/09/06/storing-a-string-in-active-storage as guide
class Chapter < ApplicationRecord
  has_one_attached :og_text
  has_one_attached :tl_text
  belongs_to :book

  def pretty_title
    if tl_title.present?
      "Chapter #{ch_number}: #{tl_title}"
    else
      "Chapter #{ch_number}"
    end
  end

  def og_text_data=(value)
    value = value.force_encoding('UTF-8')
    @og_text_data = value
    og_text.attach(
      io: StringIO.new(value),
      filename: 'og_data.txt',
      content_type: 'text/plain'
    )
  end

  def to_param
    ch_number.to_s
  end

  def og_text_data
    @og_text_data ||= og_text.blob&.download&.force_encoding('UTF-8')
  end

  def tl_text_data=(value)
    value = value.force_encoding("UTF-8")
    @tl_text_data = value
    tl_text.attach(
      io: StringIO.new(value),
      filename: 'tl_data.txt',
      content_type: 'text/plain'
    )
  end

  def tl_text_data
    @tl_text_data ||= tl_text.blob&.download&.force_encoding("UTF-8")
  end

  def previous
    book.chapters.find_by(ch_number: ch_number - 1)
  end
  def next
    book.chapters.find_by(ch_number: ch_number + 1)
  end
end
