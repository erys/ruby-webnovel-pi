# frozen_string_literal: true

# Corrupt Chapter helpers
module CorruptChaptersHelper
  def chapter_id_key(book_id, ch_number)
    "book #{book_id}, chapter #{ch_number}"
  end

  def corrupt_chapter_id(ch_number)
    Rails.cache.read(chapter_id_key(@book.id, ch_number))
  end

  def clean_chapter_url
    ch_number = @book.new_chapter_number
    corrupt_id = corrupt_chapter_id(ch_number)

    if corrupt_id && Rails.cache.read(corrupt_id)
      edit_book_corrupt_chapter_path(@book, corrupt_id)
    else
      og_chapter = OriginalChapter.where(book: @book, ch_number:).order(updated_at: :desc).first
      if og_chapter
        clean_book_original_chapter_path(@book, og_chapter)
      else

        new_book_corrupt_chapter_path(@book)
      end
    end
  end

  def cache_chapter
    Rails.cache.write(chapter_id_key(@corrupt_chapter.book_id, @corrupt_chapter.ch_number),
                      @corrupt_chapter.id,
                      expires_in: 6.hours)

    if Rails.env.development?
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter.to_json)
    else
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter, expires_in: 6.hours)
    end
  end
end
