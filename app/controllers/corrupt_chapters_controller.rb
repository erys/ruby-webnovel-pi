# frozen_string_literal: true

# Controller for corrupt chapters
class CorruptChaptersController < ApplicationController
  def create
    # TODO: #12 add check on ch_number
    # TODO: #13 add ability to overwrite existing chapter
    @book = Book.find_by(short_name: params[:book_short_name])
    cc_params = corrupt_chapter_params
    cc_params[:book_id] = @book.id
    @corrupt_chapter = init_corrupt_chapter(cc_params)
    cache_chapter
    redirect_to(edit_book_corrupt_chapter_path(@book, @corrupt_chapter))
  end

  def edit
    fetch_chapter
    @corrupt_chapter.parse
    cache_chapter
    if @corrupt_chapter.done?
      finish_chapter
    else
      gen_excerpt
    end
  end

  def update
    fetch_chapter
    if params[:commit]&.length == 1
      # TODO: #14 javascript version
      @corrupt_chapter.replace(params[:commit])

      if @corrupt_chapter.done?
        finish_chapter
        return
      end
      cache_chapter
    end
    redirect_to(edit_book_corrupt_chapter_path)
  end

  def undo
    fetch_chapter
    old_replacement = @corrupt_chapter.undo
    if old_replacement
      flash[:undo_success] = "Replace with <strong>#{old_replacement}</strong>"
    else
      flash[:undo_failure] = 'No replacements to undo'
    end
    cache_chapter
    redirect_to edit_book_corrupt_chapter_path
  end

  def new
    @book = Book.find_by(short_name: params[:book_short_name])
    @corrupt_chapter = CorruptChapter.new(book_id: @book.id)
    @corrupt_chapter.ch_number = @book.new_chapter_number
  end

  def gen_excerpt
    @excerpt = view_context.excerpt(
      @corrupt_chapter.og_text,
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

  def corrupt_chapter_params
    params.require(:corrupt_chapter).permit(:og_text, :ch_number, :subtitle)
  end

  def update_params
    params.require(:corrupt_chapter).permit(:replacement)
  end

  def init_corrupt_chapter(cc_params)
    if Rails.env.development?
      CorruptChapterJson.new(cc_params)
    else
      CorruptChapter.new(cc_params)
    end
  end

  def cache_chapter
    if Rails.env.development?
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter.to_json)
    else
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter, expires_in: 6.hours)
    end
  end

  def fetch_chapter
    @corrupt_chapter = if Rails.env.development?
                         CorruptChapterJson.from_json(Rails.cache.read(params[:id]))
                       else
                         Rails.cache.read(params[:id])
                       end
    @book = Book.find(@corrupt_chapter.book_id)
  end
end
