class CachedMovieSearch < ApplicationRecord
  belongs_to :cached_search
  belongs_to :movie
end
