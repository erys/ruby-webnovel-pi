# frozen_string_literal: true

# == Schema Information
#
# Table name: books
#
#  id                 :bigint           not null, primary key
#  description        :text
#  last_chapter       :integer
#  og_source          :string
#  og_source_link     :string
#  og_title           :string           not null
#  original_status    :string           default("Completed")
#  phonetic_title     :string
#  short_name         :string
#  tl_source          :string
#  tl_source_link     :string
#  tl_title           :string           not null
#  translation_status :string           default("In Progress")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  author_id          :integer          not null
#  jjwxc_id           :integer
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

  IN_PROGRESS = 'In Progress'
  NOT_STARTED = 'Not Started'
  COMPLETED = 'Completed'
  DROPPED = 'Dropped'
  PAUSED = 'Paused'
  CAUGHT_UP = 'Caught Up'

  BOOK_STATUSES = [
    NOT_STARTED,
    IN_PROGRESS,
    DROPPED,
    PAUSED,
    COMPLETED
  ].freeze

  TRANSLATION_STATUSES = [
    NOT_STARTED,
    IN_PROGRESS,
    CAUGHT_UP,
    DROPPED,
    PAUSED,
    COMPLETED
  ].freeze

  PRECOLLECTION = 'Precollection'
  PLANNED = 'Planned'
  TRANSLATION_DROPPED = 'Translation Dropped'
  TRANSLATION_PAUSED = 'Translation Paused'
  READING_ALONG = 'Reading Along'

  STATUS_TO_CLASS = {
    COMPLETED => 'info',
    IN_PROGRESS => 'primary',
    READING_ALONG => 'success',
    CAUGHT_UP => 'info',
    PRECOLLECTION => 'light',
    TRANSLATION_DROPPED => 'danger',
    DROPPED => 'danger',
    PAUSED => 'warning',
    TRANSLATION_PAUSED => 'warning',
    PLANNED => 'light'
  }.freeze

  belongs_to :author
  has_many :chapters, dependent: :destroy
  has_many :character_occurrences, dependent: :destroy
  has_many :original_chapters, dependent: :destroy

  validates :original_status, inclusion: { in: BOOK_STATUSES, message: '%<value>s is not a valid status' }
  validates :translation_status, inclusion: { in: TRANSLATION_STATUSES, message: '%<value>s is not a valid status' }

  after_create :create_occurrences

  def to_param
    short_name
  end

  def author_cn_name
    author&.og_name
  end

  def chapter(ch_number)
    chapters.find_by(ch_number:)
  end

  def source_chapter_count
    return last_chapter if last_chapter.present?

    latest_chapter&.ch_number || 0
  end

  def overall_status
    return PRECOLLECTION if original_status == NOT_STARTED
    return PLANNED if translation_status == NOT_STARTED
    return READING_ALONG if translation_status == CAUGHT_UP
    return TRANSLATION_DROPPED if translation_status == DROPPED
    return TRANSLATION_PAUSED if translation_status == PAUSED

    translation_status
  end

  def chapters_sorted
    @chapters_sorted ||= chapters.sort_by(&:ch_number)
  end

  def status_class
    STATUS_TO_CLASS[overall_status]
  end

  def translation_progress_percent
    return 0 unless source_chapter_count&.positive? && latest_translated_chapter.present?

    (latest_tl_ch_number * 100.0) / source_chapter_count
  end

  def cleaning_progress_percent
    return 0 unless source_chapter_count&.positive? && latest_chapter.present?

    (latest_chapter.ch_number * 100.0) / source_chapter_count
  end

  def clean_only_percent
    cleaning_progress_percent - translation_progress_percent
  end

  def source_chapter_count_display
    "#{source_chapter_count}#{'+' if original_status == IN_PROGRESS}"
  end

  def translation_progress
    if latest_tl_ch_number != latest_chapter_number
      "#{latest_tl_ch_number || 0} (#{latest_chapter_number})/#{source_chapter_count_display}"

    else
      "#{latest_tl_ch_number || 0}/#{source_chapter_count_display}"
    end
  end

  def jjwxc_url
    "https://www.jjwxc.net/onebook.php?novelid=#{jjwxc_id}" if jjwxc_id.present?
  end

  def latest_chapter
    @latest_chapter ||= chapters.max { |a, b| a.ch_number <=> b.ch_number }
  end

  def latest_chapter_number
    latest_chapter&.ch_number || 0
  end

  def latest_translated_chapter
    @latest_translated_chapter ||= chapters_sorted&.reverse&.find do |chapter|
      chapter.status == Chapter::TRANSLATED
    end
  end

  def latest_tl_ch_number
    latest_translated_chapter&.ch_number || 0
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

  def add_to_zip(zip, dir: nil)
    zip.write_deflated_file(File.nice_join(dir, 'metadata.json')) { |sink| dump_metadata(sink) }
    # empty file for typing
    zip.write_stored_file(File.nice_join(dir, 'BOOK')) { |_| }

    chapters.each { |chapter| chapter.add_to_archive(zip, dir:) }
  end

  def dump_metadata(file_io)
    JSON.dump(as_json(except: %i[id author_id], include: [:author, { chapters: { except: %i[id book_id] } }]), file_io)
  end

  private

  def create_occurrences
    Character.all.each do |character|
      CharacterOccurrence.create(book: self, character:, occurrences: 0)
    end
  end
end
