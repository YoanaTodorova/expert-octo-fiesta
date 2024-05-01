module Tmdb
  module Movies
    class FetchJob < ApplicationJob
      queue_as :default

      def perform(cached_search_id, page: nil)
        @search = CachedSearch.find(cached_search_id)
        @initial_fetch = !page
        @page = page || 1

        delete_expired_search_caches
        fetch_movies
      end

      private

      def fetch_movies
        MoviesClient.new(query: @search.query_string, page: @page).search do |search_results, total_pages|
          fetch_rest_of_pages(total_pages.to_i) if @initial_fetch

          search_results.each { |raw_movie| persist_movie(raw_movie) }

          @search.with_lock do
            @search.increment_processed_pages_count!
          end

          notify_collection_fetched if @search.processed_pages_count == @search.total_pages_count
        end
      end

      def persist_movie(raw_movie)
        movie = Movie.find_or_create_by(external_id: raw_movie['id'].to_s) do |movie|
          movie.title = raw_movie['title']
          movie.overview = raw_movie['overview']
        end
        persist_movie_image(movie, raw_movie['poster_path'])

        CachedMovieSearch.find_or_create_by(cached_search_id: @search.id, movie_id: movie.id)

      end

      def persist_movie_image(movie, poster_path)
        if poster_path
          image_url = MoviesClient::IMAGE_URL + poster_path
          Tmdb::Movies::Image::FetchJob.perform_later(movie.id, image_url)
        end
      end

      def fetch_rest_of_pages(total_pages)
        @search.update_column(:total_pages_count, total_pages)

        enqueue_rest_of_pages
      end

      def enqueue_rest_of_pages
        (2..@search.total_pages_count).to_a.each do |next_page|
          Tmdb::Movies::FetchJob.perform_later(@search.id, page: next_page)
        end
      end

      def notify_collection_fetched
        SearchesChannel.broadcast_to(@search, "movies-collection-available")
      end
      
      def delete_expired_search_caches
        CachedSearch.where(query_string: @search.query_string).where.not(id: @search.id).destroy_all
      end
    end
  end
end
