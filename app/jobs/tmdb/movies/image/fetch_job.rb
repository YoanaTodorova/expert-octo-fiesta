require 'open-uri'

module Tmdb
  module Movies
    module Image
      class FetchJob < ApplicationJob
        queue_as :default

        PERMIT_IMAGE_FORMAT = %w[png jpg jpeg].freeze

        def perform(movie_id, image_url)
          movie = Movie.find(movie_id)

          valid_image_format = get_content_type(image_url)
          file = URI.open(image_url)
          file_name = File.basename(image_url)

          movie.poster.attach(io: file, filename: file_name, content_type: valid_image_format)
        end

        private

        def get_content_type(image_url)
          ext_name = File.extname(image_url).delete('.')
          return unless PERMIT_IMAGE_FORMAT.include?(ext_name)

          "image/#{ext_name}"
        end
      end
    end
  end
end
