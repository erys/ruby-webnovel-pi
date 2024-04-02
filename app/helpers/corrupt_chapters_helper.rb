# frozen_string_literal: true

# Corrupt Chapter helpers
module CorruptChaptersHelper
  def corrupt_chapter_id
    Rails.cache.read(chapter_id_key(@book.id, params[:ch_number]))
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
