class BooksController < ApplicationController
  def index
    @books = Book.all
  end

  def new
    @book = Book.new
  end

  def show
    @book = Book.find_by(short_name: params[:short_name])
    @chapters = @book.chapters.sort_by { |chapter| chapter.ch_number }
  end

  def create
    @author = Author.find_by(og_name: params[:book][:author_cn_name])
    if @author.nil?
      @author = Author.create(og_name: params[:book][:author_cn_name])
    end
    @book = Book.new(book_params)

    if @book.save
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @book = Book.find_by(short_name: params[:short_name])
  end

  def update
    @book = Book.find_by(short_name: params[:short_name])
    @author = Author.find_by(og_name: params[:book][:author_cn_name])
    if @author.nil?
      @author = Author.create(og_name: params[:book][:author_cn_name])
    end
    @book.update!(book_params)
    redirect_to @book
  end

  private
  def book_params
    inner_params = params.require(:book).permit(:tl_title, :og_title, :description, :short_name)
    inner_params[:tl_title] = inner_params[:tl_title]&.squish
    inner_params[:author_id] = @author.id
    if inner_params[:short_name].blank?
      inner_params[:short_name] = inner_params[:tl_title].squish.split(' ').map { |word| word[0] }.join.upcase
    else
      inner_params[:short_name] = inner_params[:short_name].squish.gsub(' ', '-').upcase
    end
    inner_params 
  end
end
