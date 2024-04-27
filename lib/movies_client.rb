require 'uri'
require 'net/http'

# This class is responsible to process movies list
class MoviesClient
  URL = "https://api.themoviedb.org/3/search/movie?include_adult=false&language=en-US"

  IMAGE_URL="https://image.tmdb.org/t/p/".freeze
  IMAGE_SIZE="w300"

  attr_accessor :query, :page

  def initialize(query:, page: nil)
    self.query=query
    self.page = page || 1
  end

  def search
    fetch_movies
  end

  def fetch_movies
    response = make_request
    puts response
    format_to_movie_collection(response)
  end

  def make_request
    response = http_request.request(build_get_request)
    parse_response(response)
  end

  def http_request
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = true
    end
  end

  def build_get_request
    Net::HTTP::Get.new(uri).tap do |request|
      request["accept"] = 'application/json'
      request["Authorization"] = "Bearer #{ENV['TMDB_ACCESS_TOKEN']}"
    end
  end

  def uri
    @uri ||= URI(URL + "&query=#{query}")
  end

  def parse_response(response)
    case response.code.to_i
    when 200
      format_response(response)
    end
  end

  def format_response(response)
    JSON.parse(response.body)
  end

  def format_to_movie_collection(response)
    self.page = response['page']
    puts response['results']
    response['results'].map do |raw_movie|
      {
        title: raw_movie['title'],
        overview: raw_movie['overview'],
      }
    end
  end
end

