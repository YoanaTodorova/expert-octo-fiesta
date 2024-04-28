module Tmdb
  module Movies
    class FetchJob < ApplicationJob
      queue_as :default

      def perform(cached_search_id, page: nil)
        @search = CachedSearch.find(cached_search_id)
        @page = page

        fetch_movies
      end

      private

      def fetch_movies
        MoviesClient.new(query: @search.query_string, page: @page).search do |search_results, total_pages|
          if !@page
            @search.update_column(:total_pages_count, total_pages.to_i)

            (2..total_pages).to_a.each do |next_page|
              Tmdb::Movies::FetchJob.perform_later(@search.id, page: next_page)
            end
          end

          search_results.each do |raw_movie|
            movie = Movie.find_or_create_by(external_id: raw_movie['id'].to_s) do |movie|
              movie.title = raw_movie['title']
              movie.overview = raw_movie['overview']
            end

            #@search.movies << movie
            CachedMovieSearch.find_or_create_by(cached_search_id: @search.id, movie_id: movie.id)
          end

          @search.with_lock do
            @search.increment_processed_pages_count!
          end
        end
      end
    end
  end
end
