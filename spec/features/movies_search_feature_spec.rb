require 'rails_helper'

describe "the movie search feature", type: :feature, js: true do
  include ActiveJob::TestHelper

  fixtures :cached_searches, :movies, :cached_movie_searches

  context "user searches for a movie" do
    context "that hasn't been searched for in the past 2 minutes" do
      let(:search_term) { 'test' }

      before do
        expect(CachedSearch.recent.where(query_string: search_term).count).to eq 0

        visit root_path

        within("#search-form") do
          fill_in 'query', with: search_term
          click_button 'Search'
        end
        sleep(1)
      end

      it "renders proper feedback" do
        expect(page).to have_content("Fetching movies")
      end

      context 'when TMDB API returns 200' do
        let(:status) { 200 }
        let(:tmdb_api_movie) { { title: 'Just a movie', id: 123 } }
        let(:response_body) { <<-BODY }
        {
          "page": 1,
          "results": [
            {
              "title": "#{tmdb_api_movie[:title]}",
              "id": #{tmdb_api_movie[:id]}
            }
          ],
          "total_pages": 1,
          "total_results": 1 
        }
        BODY

        before do
          WebMock.stub_request(:any, /#{MoviesClient::URL}/).to_return(status: status, body: response_body)
        end

        context "and after background jobs are performed" do
          before do
            perform_enqueued_jobs
            assert_performed_jobs 1
          end

          it "renders movie results" do
            expect(page).to have_content('results from API')
            expect(page).to have_content(tmdb_api_movie[:title])
          end
        end
      end

      context 'when TMDB API returns error' do
        let(:status) { 500 }
        let(:response_body) { nil }

        before do
          WebMock.stub_request(:any, /#{MoviesClient::URL}/).to_return(status: status, body: response_body)
        end

        context "and after background jobs are performed" do
          before do
            perform_enqueued_jobs rescue nil
            assert_performed_jobs 1
            sleep(1)
            perform_enqueued_jobs rescue nil
            assert_performed_jobs 2
            sleep(1)
            perform_enqueued_jobs rescue nil
            assert_performed_jobs 3
            sleep(1)
          end

          xit "renders proper feedback" do
            expect(page).to have_content("There was an error fetching movies")
          end
        end
      end
    end

    context "that has been searched for in the past 2 minutes" do
      let(:existing_recent_search) { cached_searches(:office)}
      let(:search_term) { existing_recent_search.query_string }

      before do
        existing_recent_search.update_column(:created_at, 1.minutes.ago)
        expect(CachedSearch.recent.where(query_string: search_term).count).to eq 1

        visit root_path

        within("#search-form") do
          fill_in 'query', with: search_term
          click_button 'Search'
        end
        sleep(1)
      end

      it "renders movie results" do
        expect(page).to have_content("cached results")
        existing_recent_search.movies.each do |movie|
          expect(page).to have_content(movie.title)
        end
      end
    end
  end
end
