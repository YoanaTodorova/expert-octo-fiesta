require 'uri'
require 'net/http'

# This class is responsible to process movies list
class MoviesClient
  URL = "https://api.themoviedb.org/3/search/movie?"

  IMAGE_URL="https://image.tmdb.org/t/p/original".freeze

  class ApiError < StandardError; end

  attr_accessor :query, :page, :total_pages

  def initialize(query:, page: 1)
    self.query=query
    self.page = page
  end

  def search(&block)
    fetch_movies(&block)
  end

  def fetch_movies
    response = make_request
    yield response['results'], response['total_pages']
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
    @uri ||= URI(URL + "query=#{query}&page=#{page}")
  end

  def parse_response(response)
    case response.code.to_i
    when 200
      format_response(response)
    else
      raise ApiError
    end
  end

  def format_response(response)
    JSON.parse(response.body)
  end
end

