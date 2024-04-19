# frozen_string_literal: true

# Controller for chapters
class ChaptersController < ApplicationController
  before_action :find_book, except: :set_subtitle
  # TODO: #11 find/replace on english text
  #   option 1: part of normal text edit
  #   option 2: set auto find replace on a per book basis (useful for names, i.e. Lin Samuel -> Lin Huai)
  #   this would either auto replace on save, or would be a button that would give interactive view
  def show
    init_chapters
  end

  def new
    @chapter = Chapter.new
    @chapter.ch_number = @book.new_chapter_number
  end

  def create
    @chapter = Chapter.new(**chapter_params, book_id: @book.id)
    unless @chapter.save
      render :new, status: :unprocessable_entity
      return
    end
    @chapter.tl_text_data = params[:chapter][:tl_text_data]
    @chapter.og_text_data = params[:chapter][:og_text_data]
    redirect_to book_chapter_path(@book, @chapter)
  end

  # TODO: #8 delete+destroy
  # def delete
  # end

  def edit
    init_chapters
  end

  def update
    init_chapters

    @chapter.update(chapter_params)
    @chapter.tl_text_data = params[:chapter][:tl_text_data]
    @chapter.og_text_data = params[:chapter][:og_text_data]
    save_redirect
  end

  def set_subtitle
    @book = Book.find_by(jjwxc_id: params[:jjwxc_id])
    init_chapters

    return render status: :not_found, json: {} unless @chapter

    return render status: :conflict, json: {} if @chapter.og_subtitle.present?

    @chapter.update(subtitle_params)
    if @chapter.save
      render status: :ok, json: {}
    else
      render status: :internal_server_error, json: { errors: @chapter.errors }
    end
  end

  # TODO: #9 side by side text edit with chinese, keeping lines together
  # TODO: #10 rich text or markdown editing

  private

  def subtitle_params
    params.require(:chapter).permit(:og_subtitle)
  end

  def find_book
    @book = Book.find_by(short_name: params[:book_short_name])
  end

  def save_redirect
    case params[:save]
    when '& continue'
      redirect_to edit_book_chapter_path(@book, @chapter)
    when '& clean'
      redirect_to helpers.clean_chapter_url
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
