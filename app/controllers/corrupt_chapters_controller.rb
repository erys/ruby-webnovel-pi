# frozen_string_literal: true

# Controller for corrupt chapters
class CorruptChaptersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create_api, :destroy]
  before_action :fetch_chapter, only: %i[edit undo update]
  def create
    # TODO: #12 add check on ch_number
    # TODO: #13 add ability to overwrite existing chapter
    @book = Book.find_by(short_name: params[:book_short_name])
    @corrupt_chapter = init_corrupt_chapter
    helpers.cache_chapter
    redirect_to(edit_book_corrupt_chapter_path(@book, @corrupt_chapter))
  end

  def destroy
    Rails.cache.delete(id)

    redirect_to book_path(@book), status: :see_other
  end

  def create_api
    @book = Book.find_by(jjwxc_id: params[:jjwxc_id])
    @corrupt_chapter = init_corrupt_chapter
    helpers.cache_chapter
    render json: { id: @corrupt_chapter.id }
  end

  def edit
    @corrupt_chapter.parse
    helpers.cache_chapter
    if @corrupt_chapter.done?
      finish_chapter
    else
      gen_excerpt
    end
  end

  def update
    if params[:commit]&.length == 1
      # TODO: #14 javascript version
      @corrupt_chapter.replace(params[:commit])

      if @corrupt_chapter.done?
        finish_chapter
        return
      end
      helpers.cache_chapter
    end
    redirect_to(edit_book_corrupt_chapter_path)
  end

  def undo
    old_replacement = @corrupt_chapter.undo
    if old_replacement
      flash[:undo_success] = "Replace with <strong>#{old_replacement}</strong>"
    else
      flash[:undo_failure] = 'No replacements to undo'
    end
    helpers.cache_chapter
    redirect_to edit_book_corrupt_chapter_path
  end

  def new
    @book = Book.find_by(short_name: params[:book_short_name])
    @corrupt_chapter = CorruptChapter.new({ book_id: @book.id }, parts_params: {})
    @corrupt_chapter.ch_number = @book.new_chapter_number
  end

  def cur_bytes
    @book = Book.find_by(jjwxc_id: params[:jjwxc_id])
    id = helpers.corrupt_chapter_id(params[:ch_number])
    if id.blank?
      render json: { char: nil }
      return
    end
    fetch_chapter(id)
    render json: { char: @corrupt_chapter&.char_to_replace&.og_bytes || 'DONE' }
  end

  def gen_excerpt
    @excerpt = view_context.excerpt(
      @corrupt_chapter.display_text,
      @corrupt_chapter.char_to_replace.og_bytes,
      radius: 50
    )
    @corrupt_chapter.corrupt_chars.each do |corrupt_char|
      corrupt_char.highlight(@excerpt, @corrupt_chapter.char_to_replace)
    end
    @current_char = @corrupt_chapter.char_to_replace
  end

  private

  def finish_chapter
    @chapter = @corrupt_chapter.init_chapter
    @chapter.save!
    Rails.cache.delete(@corrupt_chapter.id)
    flash[:last_action] = 'clean'
    redirect_to(edit_book_chapter_path(@book, @chapter))
  end

  # @return [ActionController::Parameters]
  def corrupt_chapter_params
    params.require(:corrupt_chapter).permit(:ch_number, :subtitle, parts: {})
  end

  def update_params
    params.require(:corrupt_chapter).permit(:replacement)
  end

  def init_corrupt_chapter
    cc_params = corrupt_chapter_params
    cc_params[:book_id] = @book.id
    parts_params = cc_params.delete(:parts)

    if Rails.env.development?
      CorruptChapterJson.new(cc_params, parts_params:)
    else
      CorruptChapter.new(cc_params, parts_params:)
    end
  end

  def fetch_chapter(id = params[:id])
    @corrupt_chapter = if Rails.env.development?
                         CorruptChapterJson.from_json(Rails.cache.read(id))
                       else
                         Rails.cache.read(id)
                       end
    @book = Book.find(@corrupt_chapter.book_id) if @corrupt_chapter
  end
end
