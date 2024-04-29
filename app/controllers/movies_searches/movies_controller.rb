class MoviesSearches::MoviesController < ActionController::Base
  before_action :load_search

  def index
    @page = params[:page]
    respond_to do |format|
      format.js
    end
  end

  private

  def load_search
    @search = CachedSearch.find(params[:movies_search_id])
  end
end
