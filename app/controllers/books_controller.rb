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

  before_action :populate_author, only: %i[update create update_api create_api]
  before_action :find_book, only: %i[show edit update destroy backup]
  before_action :find_jjwxc_book, only: %i[update_api status]
  before_action :sort_chapters, only: %i[show backup]

  skip_before_action :verify_authenticity_token, only: %i[update_api create_api]

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
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_api
    @author = Author.maybe_create_author(**author_params)
    @book = Book.new(book_params)
    if @book.save
      render json: { book: @book.id }
    else
      render json: { errors: @book.errors }, status: :unprocessable_entity
    end
  end

  def update_api
    @author = Author.maybe_create_author(**author_params)
    if @author.jjwxc_id.blank?
      @author.jjwxc_id = params[:author][:jjwxc_id]
      @author.save!
    end
    @book.update!(api_update_params)

    render json: { short_name: @book.short_name, status: @book.original_status, latest_chapter: @book.last_chapter }
  end

  def status
    if @book
      render json: { short_name: @book.short_name, status: @book.original_status, latest_chapter: @book.last_chapter }
    else
      render json: {}, status: :not_found
    end
  end

  def update
    @book.update!(book_params)
    redirect_to @book
  end

  def destroy
    @book.destroy
    redirect_to root_path, status: :see_other
  end

  def backup
    response.headers['Content-Disposition'] =
      "attachment; filename=#{@book.short_name}-#{Time.zone.now.strftime('%Y-%m-%d_%H_%M_%S')}.zip"
    zip_tricks_stream do |zip|
      @book.add_to_zip(zip)
    end
  end

  def restore
    Zip::File.open_buffer(params[:backup].to_io) do |zip|
      if zip.find_entry('LIBRARY')
        zip.read('LIBRARY').split("\n").each { |short_name| Backup.restore_book(zip, short_name) }
        redirect_to books_path
      else
        book = Backup.restore_book(zip)
        redirect_to book
      end
    end
  end

  private

  def populate_author
    @author = Author.maybe_create_author(**author_params)
  end

  def find_book
    @book = Book.find_by(short_name: params[:short_name])
    @page_title = @book.tl_title
  end

  def find_jjwxc_book
    @book = Book.find_by(jjwxc_id: params[:jjwxc_id])
  end

  def sort_chapters
    @chapters = @book.chapters_sorted
  end

  def author_params
    if params[:author].present?
      params.require(:author).permit(:og_name, :jjwxc_id)
    else
      { og_name: params[:book][:author_cn_name] }
    end
  end

  def api_update_params
    inner_params = params.require(:book).permit(:og_title, :original_status, :last_chapter, :og_description)
    inner_params[:author_id] = @author.id
    inner_params
  end

  def book_params
    inner_params = params.require(:book).permit(:tl_title, :og_title, :description, :short_name,
                                                :jjwxc_id, :original_status, :translation_status,
                                                :last_chapter, :og_description)
    inner_params[:tl_title] = inner_params[:tl_title]&.squish
    inner_params[:author_id] = @author.id
    inner_params[:short_name] = generate_short_name(
      inner_params[:tl_title],
      inner_params[:short_name],
      inner_params[:jjwxc_id],
    )
    inner_params
  end

  def generate_short_name(tl_title, short_name, jjwxc_id)
    if short_name.blank? && tl_title.present?
      tl_title.squish.split.pluck(0).join.upcase
    else
      short_name&.squish&.gsub(' ', '-')&.upcase.presence || jjwxc_id
    end
  end
end
