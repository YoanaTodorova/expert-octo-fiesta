require 'rails_helper'

RSpec.describe Tmdb::Movies::FetchJob do
  include ActiveJob::TestHelper

  fixtures :movies

  describe "#perform" do
    let(:job) { Tmdb::Movies::FetchJob.new }
    subject { job.perform(cached_search.id, **params) }

    context "with cached_search_id param" do
      let(:movies_client) { double(:movies_client) }
      before do
        allow(MoviesClient).to receive(:new).and_return(movies_client)
        allow(movies_client).to receive(:search).and_yield(movie_results, total_pages)
        allow(SearchesChannel).to receive(:broadcast_to).and_return(true)
      end
      let(:query_string) { "let's test it" }
      let(:cached_search) { CachedSearch.create(query_string: query_string) }

      context "and no page param" do
        let(:params) { {} }
        let(:existing_movie_attributes) { movies(:lets_test_it_part_1).attributes.slice('title', 'external_id') }
        let(:new_movie_attributes) { { 'title' => "lets test it part 2", 'external_id' => 3, 'poster_path' => '/some/path' }}
        let(:movie_results) {
          [
            existing_movie_attributes,
            new_movie_attributes
          ]
        }
        let(:total_pages) { 3 }

        it 'calls MoviesClient with correct params' do
          subject

          expect(MoviesClient).to have_received(:new).with({ query: query_string, page: 1})
        end

        it 'creates only missing movies' do
          expect { subject }.to change { Movie.count }.by(1)
        end

        it 'enqueues jobs for image fetching only for movies with poster_path attribute' do
          expect { subject }.to have_enqueued_job(Tmdb::Movies::Image::FetchJob).exactly(1)
        end

        it "enqueues job #{described_class} for the rest of the pages" do
          expect { subject }.to have_enqueued_job(described_class).exactly(total_pages - 1)
        end

        it 'updates processed_pages_count of cached_search' do
          expect { subject; cached_search.reload }.to change(cached_search, :processed_pages_count).from(0).to(1)
        end
      end

      context "and with page param" do
        let(:params) { { page: 2 } }
        let(:movie_results) { [] }
        let(:total_pages) { 2 }

        it "doesn't enqueue any jobs" do
          expect { subject }.not_to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size)
        end

        context 'when last page is processed' do
          before do
            cached_search.update_columns(processed_pages_count: params[:page] - 1, total_pages_count: total_pages)
          end

          it 'broadcasts message to searches channel' do
            subject

            expect(SearchesChannel).to have_received(:broadcast_to).with(cached_search, 'movies-collection-available').once
          end
        end
      end
    end
  end
end