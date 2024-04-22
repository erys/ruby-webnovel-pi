# frozen_string_literal: true

# == Schema Information
#
# Table name: original_chapters
#
#  id            :bigint           not null, primary key
#  ch_number     :integer          not null
#  font_name     :string
#  footnote      :text
#  link          :string
#  main_text     :text
#  substitutions :string           default([]), is an Array
#  subtitle      :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  book_id       :bigint           not null
#
# Indexes
#
#  index_original_chapters_on_book_id  (book_id)
#
# Foreign Keys
#
#  fk_rails_...  (book_id => books.id)

require 'open-uri'
class OriginalChapter < ApplicationRecord
  belongs_to :book
  has_one_attached :html
  has_one_attached :font_file

  def download_font(force: false)
    return if font_name.blank?
    return if font_file.attached? && !force

    font_file.attach(
      io: URI.open("https://static.jjwxc.net/tmp/fonts/#{font_name}.woff2?h=my.jjwxc.net"),
      content_type: 'font/woff2',
      filename: 'font.woff2',
      identify: false,
    )
  end

  def html_data=(value)
    value = value&.force_encoding('UTF-8').presence
    return if html_data == value

    @html_data = value || ''
    html.attach(
      io: StringIO.new(@html_data),
      filename: 'chapter.html',
      content_type: 'text/html',
    )
  end

  def as_corrupt_chapter
    CorruptChapter.new({ ch_number:, subtitle:, book_id:, original_chapter_id: id },
                       parts_params: { title:, main_text:, footnote:, substitutions: })
  end

  def html_data
    @html_data ||= html.blob&.download&.force_encoding('UTF-8')
  end
end
