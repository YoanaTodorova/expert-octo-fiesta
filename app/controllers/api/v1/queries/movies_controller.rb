class Api::V1::Queries::MoviesController < ActionController::Base
  respond_to :json

  def index
    respond_with [1,2,3]
  end
end
