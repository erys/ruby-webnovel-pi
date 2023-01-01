# frozen_string_literal: true

# Controller for books
class BooksController < ApplicationController
  include ZipTricks::RailsStreaming
  require 'tempfile'

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
  end

  def new
    @book = Book.new
  end

  def show; end

  def create
    @author = Author.find_by(og_name: params[:book][:author_cn_name])
    @author = Author.create(og_name: params[:book][:author_cn_name]) if @author.nil?
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @author = Author.find_by(og_name: params[:book][:author_cn_name])
    @author = Author.create(og_name: params[:book][:author_cn_name]) if @author.nil?
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

  private

  def find_book
    @book = Book.find_by(short_name: params[:short_name])
  end

  def sort_chapters
    @chapters = @book.chapters.sort_by(&:ch_number)
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
