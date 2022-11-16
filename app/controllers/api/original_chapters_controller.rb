# frozen_string_literal: true

module Api
  # api only controller for original chapters
  class OriginalChaptersController < ApplicationController

    # POST /api/original_chapters
    # POST /api/original_chapters.json
    def create
      @original_chapter = OriginalChapter.new(original_chapter_params)

      @original_chapter.html_data = params[:original_chapter][:html]
      if @original_chapter.save
        render json: { book: @original_chapter.book.tl_title, ch_number: @original_chapter.ch_number },
               status: :created,
               location: @original_chapter
      else
        render json: @original_chapter.errors, status: :unprocessable_entity
      end
    end

    private

    # Only allow a list of trusted parameters through.
    def original_chapter_params
      og_chap_params = params.require(:original_chapter).permit(:ch_number, :link)
      og_chap_params[:book] = Book.find_by(jjwxc_id: params[:original_chapter][:novel_id])
      og_chap_params
    end
  end
end
