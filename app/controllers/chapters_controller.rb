class ChaptersController < ApplicationController
  def show
    @book = Book.find_by(short_name: params[:book_short_name])
    @chapter = @book.chapters.find { |chapter| chapter.ch_number.to_s == params[:ch_number] }
    @previous = @chapter.previous
    @next = @chapter.next
  end

  def new
    @book = Book.find_by(short_name: params[:book_short_name])
    @chapter = Chapter.new
    @chapter.ch_number = @book.new_chapter_number
  end

  def create
    @book = Book.find_by(short_name: params[:book_short_name])
    @chapter = Chapter.new(**chapter_params, book_id: @book.id)
    tl_text = params[:chapter][:tl_text_data]
    og_text = params[:chapter][:og_text_data]
    if @chapter.save
      @chapter.tl_text_data = tl_text if tl_text.present?
      @chapter.og_text_data = og_text if og_text.present?
      redirect_to book_chapter_path(@book, @chapter)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def clean
    @book = Book.find_by(short_name: params[:book_short_name])
    @occurrences = CharacterOccurrence.where(book: @book).sort
  end

  def delete
  end

  def edit
    @book = Book.find_by(short_name: params[:book_short_name])
    @chapter = @book.chapters.find { |chapter| chapter.ch_number.to_s == params[:ch_number] }
  end

  def update
    @book = Book.find_by(short_name: params[:book_short_name])
    @chapter = @book.chapters.find { |chapter| chapter.ch_number.to_s == params[:ch_number] }
    tl_text = params[:chapter][:tl_text_data] || ''
    og_text = params[:chapter][:og_text_data] || ''
    @chapter.update(chapter_params)
    if @chapter.tl_text_data != tl_text
      @chapter.tl_text_data = tl_text
    end
    @chapter.og_text_data = og_text if @chapter.og_text_data != og_text
    redirect_to book_chapter_url(@book)
  end

  private

  def chapter_params
    params.require(:chapter).permit(:og_title, :ch_number, :tl_title)

  end

end
