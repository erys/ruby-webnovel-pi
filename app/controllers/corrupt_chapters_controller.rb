class CorruptChaptersController < ApplicationController
  def create
    @book = Book.find_by(short_name: params[:book_short_name])
    cc_params = corrupt_chapter_params
    cc_params[:book_id] = @book.id
    @corrupt_chapter = CorruptChapter.new(cc_params)
    cache_chapter
    redirect_to(edit_book_corrupt_chapter_path(@book, @corrupt_chapter))
  end

  def edit
    fetch_chapter
    @corrupt_chapter.parse
    cache_chapter
    @book = Book.find(@corrupt_chapter.book_id)
    if @corrupt_chapter.done?
      @chapter = @corrupt_chapter.init_chapter
      @chapter.save!
      Rails.cache.delete(@corrupt_chapter.id)
      flash[:last_action] = 'clean'
      redirect_to(edit_book_chapter_path(@book, @chapter))
    else
      @excerpt = gen_excerpt
    end
  end

  def update
    fetch_chapter
    @book = Book.find(@corrupt_chapter.book_id)
    char = params[:commit]
    unless char&.length == 1
      redirect_to(edit_book_corrupt_chapter_path)
      return
    end
    # unless update_params[:replacement].present?
    #   redirect_to(edit_book_corrupt_chapter_path(@book, @corrupt_chapter))
    #   return
    # end
    @corrupt_chapter.replace(char)
    # raise "blah"
    #
    if @corrupt_chapter.done?
      @chapter = @corrupt_chapter.init_chapter
      @chapter.save!
      Rails.cache.delete(@corrupt_chapter.id)
      flash[:last_action] = 'clean'
      redirect_to(edit_book_chapter_path(@book, @chapter))
    else
      cache_chapter
      # raise "blah"
      redirect_to(edit_book_corrupt_chapter_path(@book, @corrupt_chapter))
      #TODO javascript version
    end
  end

  def undo
    fetch_chapter
    @book = Book.find(@corrupt_chapter.book_id)
    old_replacement = @corrupt_chapter.undo
    if old_replacement
      flash[:undo_success] = "Replace with <strong>#{old_replacement}</strong>"
    else
      flash[:undo_failure] = "No replacements to undo"
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
    excerpt = view_context.excerpt(
      @corrupt_chapter.og_text, 
      @corrupt_chapter.char_to_replace.og_bytes, 
      radius: 100
    )
    @corrupt_chapter.corrupt_chars.each do |corrupt_char|
      corrupt_char.highlight(excerpt, @corrupt_chapter.char_to_replace)
    end
    @current_char = @corrupt_chapter.char_to_replace
    excerpt
  end

  private
  def corrupt_chapter_params
    params.require(:corrupt_chapter).permit(:og_text, :ch_number, :subtitle)
  end

  def update_params
    params.require(:corrupt_chapter).permit(:replacement)
  end

  def cache_chapter
    if Rails.env.development?
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter.to_json)
    else
      Rails.cache.write(@corrupt_chapter.id, @corrupt_chapter, expires_in: 1.hour)
    end
  end

  def fetch_chapter
    if Rails.env.development?
      @corrupt_chapter = CorruptChapter.from_json(Rails.cache.read(params[:id]))
    else
      @corrupt_chapter = Rails.cache.read(params[:id])
    end
  end
end
