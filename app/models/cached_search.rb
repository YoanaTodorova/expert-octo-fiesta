class CachedSearch < ApplicationRecord
  has_many :cached_movie_searches, inverse_of: :cached_search, dependent: :destroy
  has_many :movies, through: :cached_movie_searches
end
