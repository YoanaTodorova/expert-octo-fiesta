class Movie < ApplicationRecord
  has_many :cached_movie_searches, inverse_of: :movie, dependent: :destroy
end
