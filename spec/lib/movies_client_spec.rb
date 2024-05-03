require 'rails_helper'

RSpec.describe 'MoviesClient' do
  describe '#new' do
    subject { MoviesClient.new(**params) }

    context 'without page param' do
      let(:params) { { query: 'something' } }

      it 'sets page to 1' do
        expect(subject.page).to eq 1
      end
    end
  end

  describe '.search' do
    context 'when TMDB API returns 200' do
      let(:params) { { query: 'something' } }

      let(:status) { 200 }
      let(:tmdb_api_movies) { [{ 'title' => 'Just a movie', 'id' => 123 }, { 'title' => 'Just a movie pt2', 'id' => 456 }] }
      let(:total_pages) { 1 }
      let(:response_body) { <<-BODY }
        {
          "page": 1,
          "results": #{tmdb_api_movies.to_json},
          "total_pages": #{total_pages},
          "total_results": 2 
        }
    BODY

      before do
        WebMock.stub_request(:any, /#{MoviesClient::URL}/).to_return(status: status, body: response_body)
      end

      it 'yields the results and total pages' do
        expect { |b| MoviesClient.new(**params).search(&b) }.to yield_with_args(tmdb_api_movies, total_pages)
      end
    end

    context 'when TMDB API returns error' do
      let(:params) { { query: 'something' } }

      let(:status) { 500 }
      let(:response_body) { nil }

      before do
        WebMock.stub_request(:any, /#{MoviesClient::URL}/).to_return(status: status, body: response_body)
      end

      it 'raises an error' do
        expect { |b| MoviesClient.new(**params).search(&b) }.to raise_error(MoviesClient::ApiError)
      end
    end
  end
end