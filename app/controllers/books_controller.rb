# frozen_string_literal: true

require 'zip'
require 'zip/filesystem'

# Controller for books
class BooksController < ApplicationController
  include ZipTricks::RailsStreaming

  CATEGORIES = {
    current: [Book::READING_ALONG, Book::IN_PROGRESS],
    up_next: [Book::TRANSLATION_PAUSED, Book::PLANNED],
    done: [Book::COMPLETED],
    other: [Book::TRANSLATION_DROPPED, Book::PRECOLLECTION],
    all: nil
  }.freeze

  DEFAULT_CATEGORY = :current

  before_action :find_book, only: %i[show edit update destroy backup]
  before_action :sort_chapters, only: %i[show backup]

  def index
    @books = Book.all.sort
    @page_title = 'erys\'s danmei library'
  end

  def show; end

  def new
    @page_title = 'Add a new novel'
    @book = Book.new
  end

  def edit; end

  def create
    populate_author
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    populate_author
    @book.update!(book_params)
    redirect_to @book
  end

  def destroy
    @book.destroy
    redirect_to root_path, status: :see_other
  end

  def backup
    response.headers['Content-Disposition'] =
      "attachment; filename=#{@book.short_name}-#{Time.now.strftime('%Y-%m-%d_%H_%M_%S')}.zip"
    zip_tricks_stream do |zip|
      @book.add_to_zip(zip)
    end
  end

  def restore
    Zip::File.open_buffer(params[:backup].to_io) do |zip|
      if zip.find_entry('LIBRARY')
        zip.read('LIBRARY').split("\n").each { |short_name| restore_book(zip, short_name) }
        redirect_to books_path
      else
        book = restore_book(zip)
        redirect_to book
      end
    end
  end

  private

  def populate_author
    @author = maybe_create_author(params[:book][:author_cn_name])
  end

  def maybe_create_author(og_name)
    Author.find_by(og_name:) || Author.create(og_name:)
  end

  def restore_book(zip, dir_name = nil)
    zip.get_entry(File.nice_join(dir_name, 'BOOK'))
    metadata_json = JSON.parse(zip.read(File.nice_join(dir_name, 'metadata.json'))).with_indifferent_access
    book = find_dup_book(metadata_json)

    book_params = metadata_json.slice(*Book.column_names)
    book_params[:author] = maybe_create_author(metadata_json[:author][:og_name])
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
    chapter.touch(time: ch_metadata[:updated_at])
  end

  def update_chapter_text_from_zip(chapter, dir_name, zip)
    english = zip.find_entry(chapter.get_english_file_name(dir_name))
    chinese = zip.find_entry(chapter.get_chinese_file_name(dir_name))
    chapter.og_text_data = chinese.get_input_stream.read if chinese
    chapter.tl_text_data = english.get_input_stream.read if english
  end

  def find_book
    @book = Book.find_by(short_name: params[:short_name])
    @page_title = @book.tl_title
  end

  def sort_chapters
    @chapters = @book.chapters_sorted
  end

  def book_params
    inner_params = params.require(:book).permit(:tl_title, :og_title, :description, :short_name,
                                                :jjwxc_id, :original_status, :translation_status,
                                                :last_chapter)
    inner_params[:tl_title] = inner_params[:tl_title]&.squish
    inner_params[:author_id] = @author.id
    inner_params[:short_name] = generate_short_name(inner_params[:tl_title], inner_params[:short_name])
    inner_params
  end

  def generate_short_name(tl_title, short_name)
    if short_name.blank? && tl_title.present?
      tl_title.squish.split(' ').map { |word| word[0] }.join.upcase
    else
      short_name&.squish&.gsub(' ', '-')&.upcase
    end
  end
end
