class CachedSearch < ApplicationRecord
  has_many :cached_movie_searches, inverse_of: :cached_search, dependent: :destroy
  has_many :movies, through: :cached_movie_searches

  CACHE_TTL = 2.minutes

  def self.recent
    where("created_at >= ?", Time.now - CACHE_TTL)
  end

  def self.expired
    where("created_at < ?", Time.now - CACHE_TTL)
  end

  def increment_hit_count!
    update_column(:hit_count, hit_count + 1)
  end

  def increment_processed_pages_count!
    update_column(:processed_pages_count, processed_pages_count + 1)
  end
end
