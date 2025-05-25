class BooksController < ApplicationController
  # NOTE: The following URLs are hard-coded by published books.
  # And the books are just a few, so not a big problem for now.
  # https://github.com/coderdojo-japan/coderdojo.jp/pull/1696

  # GET /sotechsha[2]
  def sotechsha1_index; render("books/sotechsha1/index"); end
  def sotechsha2_index; render("books/sotechsha2/index"); end

  # GET /sotechsha[2]/:page
  def sotechsha1_show; render_book_page(params); end
  def sotechsha2_show; render_book_page(params); end

  private

  def render_book_page(params)
    book_title = params[:action].split('_').first
    Book.exist?(book_title, params[:page]) ?
      render("books/#{book_title}/#{params[:page]}") :
      redirect_to("/#{book_title}", flash: { warning: '該当するページが見つかりませんでした 💦'} )
  end
end
