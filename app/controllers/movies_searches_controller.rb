class MoviesSearchesController < ActionController::Base
  before_action :create_search

  def create
    respond_to do |format|
      format.js
    end
  end

  private

  def create_search
    @search = MoviesSearch.create(query_string: params[:query])
  end
end
