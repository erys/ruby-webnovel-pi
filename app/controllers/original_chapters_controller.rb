# frozen_string_literal: true

# api only controller for original chapters
class OriginalChaptersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @original_chapter = OriginalChapter.new(original_chapter_params)

    if @original_chapter.save
      @original_chapter.download_font

      auto_cleaned = maybe_auto_clean

      render json: {
               book: @original_chapter.book.short_name,
               ch_number: @original_chapter.ch_number,
               original_chapter_id: @original_chapter.id,
               auto_cleaned:
             },
             status: :created
    else
      render json: @original_chapter.errors, status: :unprocessable_entity
    end
  end

  def clean
    @book = Book.find_by(short_name: params[:book_short_name])
    @original_chapter = OriginalChapter.where(book: @book, ch_number: params[:ch_number]).order(created_at: :desc).first
    if @original_chapter.blank?
      redirect_to new_book_corrupt_chapter_path(@book)
      return
    end

    if @original_chapter.equiv_chapter
      redirect_to edit_book_chapter_path(@book, @original_chapter.equiv_chapter)
      return
    end

    @corrupt_chapter = @original_chapter.as_corrupt_chapter
    helpers.cache_chapter

    redirect_to edit_book_corrupt_chapter_path(@book, @corrupt_chapter.id)
  end

  private

  # Only allow a list of trusted parameters through.
  def original_chapter_params
    og_chap_params = params.require(:original_chapter).permit(
      :ch_number,
      :link,
      :footnote,
      :font_name,
      :main_text,
      :subtitle,
      :title,
      substitutions: [],
    )
    og_chap_params[:book] = Book.find_by(jjwxc_id: params[:jjwxc_id])
    og_chap_params
  end

  def maybe_auto_clean
    return false if @original_chapter.equiv_chapter.present?

    @corrupt_chapter = @original_chapter.as_corrupt_chapter
    @corrupt_chapter.parse
    if @corrupt_chapter.corrupt_chars.all_guessed?
      @corrupt_chapter.corrupt_chars.confirm_guesses
      @chapter = @corrupt_chapter.init_chapter
      @chapter.save!
      return true
    end

    false
  end
end
