# frozen_string_literal: true

# Corrupt Chapter helpers
module CorruptChaptersHelper
  def chapter_id_key(book_id, ch_number)
    "book #{book_id}, chapter #{ch_number}"
  end

  # @param book [Book]
  # @param ch_number [Integer]
  def corrupt_chapter_id(book, ch_number)
    Rails.cache.read(chapter_id_key(book.id, ch_number))
  end

  # @param book [Book]
  # @param ch_number [Integer]
  def clean_chapter_url(book, ch_number = nil)
    ch_number ||= book.new_chapter_number
    corrupt_id = corrupt_chapter_id(book, ch_number)

    if corrupt_id && Rails.cache.read(corrupt_id)
      edit_book_corrupt_chapter_path(book, corrupt_id)
    else
      clean_book_original_chapter_path(book, ch_number)
    end
  end

  # @param corrupt_chapter [CorruptChapter]
  def cache_chapter(corrupt_chapter)
    Rails.cache.write(chapter_id_key(corrupt_chapter.book_id, corrupt_chapter.ch_number),
                      corrupt_chapter.id,
                      expires_in: 6.hours)

    if Rails.env.development?
      Rails.cache.write(corrupt_chapter.id, corrupt_chapter.to_json)
    else
      Rails.cache.write(corrupt_chapter.id, corrupt_chapter, expires_in: 6.hours)
    end
  end
end
