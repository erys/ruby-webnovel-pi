# frozen_string_literal: true

# == Schema Information
#
# Table name: original_chapters
#
#  id         :bigint           not null, primary key
#  ch_number  :integer          not null
#  font_name  :string
#  link       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  book_id    :bigint           not null
#
# Indexes
#
#  index_original_chapters_on_book_id  (book_id)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)
#
class OriginalChapter < ApplicationRecord
  belongs_to :book
  has_one_attached :html

  def html_data=(value)
    value = value&.force_encoding('UTF-8').presence
    return if html_data == value

    @html_data = value || ''
    html.attach(
      io: StringIO.new(@html_data),
      filename: 'chapter.html',
      content_type: 'text/html'
    )
  end

  def html_data
    @html_data ||= html.blob&.download&.force_encoding('UTF-8')
  end
end
