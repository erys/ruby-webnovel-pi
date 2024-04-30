# frozen_string_literal: true

# class for handling backup/restore functions
class Backup
  class << self
    def restore_book(zip, dir_name = nil)
      zip.get_entry(File.nice_join(dir_name, 'BOOK'))
      metadata_json = JSON.parse(zip.read(File.nice_join(dir_name, 'metadata.json'))).with_indifferent_access
      book = find_dup_book(metadata_json)

      book_params = metadata_json.slice(*Book.column_names)
      book_params[:author] = Author.maybe_create_author(**metadata_json[:author].symbolize_keys)
      if book && book.updated_at.iso8601 < metadata_json[:updated_at]
        book.update!(book_params)
      elsif book.nil?
        book = Book.create!(book_params)
      end

      metadata_json[:chapters].each do |chapter_json|
        restore_chapter(zip, dir_name, book, chapter_json)
      end
      book
    end

    private

    def find_dup_book(book_metadata)
      book = nil
      book = Book.find_by(jjwxc_id: book_metadata[:jjwxc_id]) if book_metadata[:jjwxc_id]
      book || Book.find_by(og_title: book_metadata[:og_title])
    end

    def restore_chapter(zip, dir_name, book, ch_metadata)
      chapter = book.chapter(ch_metadata[:ch_number])
      return chapter if chapter && (chapter.updated_at.iso8601 >= ch_metadata[:updated_at])

      if chapter
        chapter.update!(ch_metadata)
      else
        ch_metadata[:book] = book
        chapter = Chapter.create!(ch_metadata)
      end

      update_chapter_text_from_zip(chapter, dir_name, zip)

      # fix updated_at to match archive since active storage upload touches it
      #
      chapter.touch(time: ch_metadata[:updated_at]) # rubocop:disable Rails/SkipsModelValidations
    end

    def update_chapter_text_from_zip(chapter, dir_name, zip)
      english = zip.find_entry(chapter.get_english_file_name(dir_name))
      chinese = zip.find_entry(chapter.get_chinese_file_name(dir_name))
      chapter.og_text_data = chinese.get_input_stream.read if chinese
      chapter.tl_text_data = english.get_input_stream.read if english
    end
  end
end
