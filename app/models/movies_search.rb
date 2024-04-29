class MoviesSearch
  attr_reader :query_string, :cached, :processing

  def self.create(**params)
    new(**params).tap(&:create)
  end

  def initialize(query_string:)
    self.query_string = query_string
  end

  def create
    self.search = find_and_update_cached_search || create_cached_search
  end

  delegate :id, :movies, :hit_count, to: :search

  private

  attr_accessor :search
  attr_writer :query_string, :cached, :processing

  def find_and_update_cached_search
    CachedSearch.recent.find_by(query_string: query_string).tap do |cached_search|
      cached_search && cached_search.increment_hit_count! && self.processing = false
    end
  end

  def create_cached_search
    CachedSearch.create!(query_string: query_string).tap do |search|
      self.processing = true
      Tmdb::Movies::FetchJob.perform_later(search.id)
    end
  end
end