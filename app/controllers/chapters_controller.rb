# frozen_string_literal: true

# Controller for chapters
class ChaptersController < ApplicationController
  # TODO: find/replace on english text
  #   option 1: part of normal text edit
  #   option 2: set auto find replace on a per book basis (useful for names, i.e. Lin Samuel -> Lin Huai)
  #   this would either auto replace on save, or would be a button that would give interactive view
  def show
    find_book
    init_chapters
  end

  def new
    find_book
    @chapter = Chapter.new
    @chapter.ch_number = @book.new_chapter_number
  end

  def create
    find_book
    @chapter = Chapter.new(**chapter_params, book_id: @book.id)
    unless @chapter.save
      render :new, status: :unprocessable_entity
      return
    end
    @chapter.tl_text_data = params[:chapter][:tl_text_data]
    @chapter.og_text_data = params[:chapter][:og_text_data]
    redirect_to book_chapter_path(@book, @chapter)
  end

  # TODO: delete+destroy
  # def delete
  # end

  def edit
    find_book
    init_chapters
  end

  def update
    find_book
    init_chapters

    @chapter.update(chapter_params)
    @chapter.tl_text_data = params[:chapter][:tl_text_data]
    @chapter.og_text_data = params[:chapter][:og_text_data]
    save_redirect
  end

  # TODO: side by side text edit with chinese, keeping lines together
  # TODO: rich text or markdown editing

  private

  def find_book
    @book = Book.find_by(short_name: params[:book_short_name])
  end

  def save_redirect
    case params[:save]
    when '& continue'
      redirect_to edit_book_chapter_path(@book, @chapter)
    when '& clean'
      redirect_to new_book_corrupt_chapter_path(@book)
    when '& edit next'
      redirect_to edit_book_chapter_path(@book, @next)
    else
      redirect_to book_chapter_url(@book)
    end
  end

  def chapter_params
    ch_params = params.require(:chapter).permit(:og_title, :ch_number, :tl_title, :og_subtitle, :tl_subtitle)
    if ch_params[:tl_title].blank? && params[:chapter][:tl_text_data].present?
      ch_params[:tl_title] = params[:chapter][:tl_text_data].lines.first.strip
    end
    ch_params
  end

  def init_chapters
    @chapter = @book.chapters.find { |chapter| chapter.ch_number.to_s == params[:ch_number] }
    @previous = @chapter.previous
    @next = @chapter.next
  end
end
