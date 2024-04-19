# frozen_string_literal: true

# api only controller for original chapters
class OriginalChaptersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    @original_chapter = OriginalChapter.new(original_chapter_params)

    if @original_chapter.save
      @original_chapter.download_font
      render json: { book: @original_chapter.book.tl_title,
                     ch_number: @original_chapter.ch_number,
                     font: url_for(@original_chapter.font_file) },
             status: :created,
             location: @original_chapter
    else
      render json: @original_chapter.errors, status: :unprocessable_entity
    end
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
      :substitutions,
      :title
    )
    og_chap_params[:book] = Book.find_by(jjwxc_id: params[:novel_id])
    og_chap_params
  end
end
