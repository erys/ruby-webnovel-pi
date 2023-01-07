# frozen_string_literal: true

# == Schema Information
#
# Table name: chapters
#
#  id          :bigint           not null, primary key
#  ch_number   :integer
#  og_subtitle :string
#  og_title    :string
#  tl_subtitle :string
#  tl_title    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  book_id     :integer          not null
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

  after_create :maybe_inc_book_last_chapter

  # TODO: #17 add arc model

  def pretty_title
    if tl_title.present?
      "Chapter #{ch_number}: #{tl_title}"
    else
      "Chapter #{ch_number}"
    end
  end

  def og_text_data=(value)
    value = value&.force_encoding('UTF-8').presence
    return if og_text_data == value

    @og_text_data = value || ''
    og_text.attach(
      io: StringIO.new(@og_text_data),
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
    value = value&.force_encoding('UTF-8').presence
    return if tl_text_data == value

    @tl_text_data = value || ''
    tl_text.attach(
      io: StringIO.new(@tl_text_data),
      filename: 'tl_data.txt',
      content_type: 'text/plain'
    )
  end

  def tl_text_data
    @tl_text_data ||= tl_text.blob&.download&.force_encoding('UTF-8')
  end

  def previous
    book.chapters.find_by(ch_number: ch_number - 1)
  end

  def next
    book.chapters.find_by(ch_number: ch_number + 1)
  end

  def chapter_json
    json = as_json(except: %i[id book_id])
    json['og_text']
  end

  def add_to_archive(zip, dir: nil)
    copy_to_archive(zip, og_text, get_chinese_file_name(dir))
    copy_to_archive(zip, tl_text, get_english_file_name(dir))
  end

  def get_english_file_name(dir = nil)
    File.nice_join(dir, 'english', "#{ch_number}.txt")
  end

  def get_chinese_file_name(dir = nil)
    File.nice_join(dir, 'chinese', "#{ch_number}.txt")
  end

  private

  def copy_to_archive(zip, attached, filename)
    return unless attached.attached?

    zip.write_deflated_file(filename, modification_time: updated_at) do |sink|
      attached.download do |chunk|
        sink << chunk
      end
    end
  end

  def maybe_inc_book_last_chapter
    return if book.last_chapter.present? && book.last_chapter >= ch_number

    book.last_chapter = ch_number
    book.save
  end
end
