require 'rails_helper'

RSpec.describe 'MoviesSearch' do
  include ActiveJob::TestHelper

  fixtures :movies, :cached_searches, :cached_movie_searches

  describe '#create' do
    subject { MoviesSearch.create(**params) }

    context 'without query_string' do
      let(:params) { {} }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'with query_string' do
      let(:office_search) { cached_searches(:office) }
      let(:params) { { query_string: office_search.query_string } }

      context 'and no cached searches' do
        let(:newly_created_search) { CachedSearch.find_by(query_string: params[:query_string]) }
        before do
          allow(CachedSearch).to receive(:recent).and_return(CachedSearch.none)
        end

        it 'creates a search' do
          expect { subject }.to change { CachedSearch.count }.by(1)
        end

        it 'enqueues job Tmdb::Movies::FetchJob' do
          expect {
            subject
          }.to have_enqueued_job(Tmdb::Movies::FetchJob).with { |arg| arg == newly_created_search.id }.once
        end

        it 'sets its processing to true' do
          expect(subject.processing).to be_truthy
        end
      end

      context 'and there are cached searches' do
        it 'finds the correct search' do
          expect(subject.id).to eq(office_search.id)
        end

        it 'sets its processing to false' do
          expect(subject.processing).to be_falsy
        end

        it 'delegates movies to the underlying search record' do
          expect(subject.movies).to eq(office_search.movies)
        end
      end
    end
  end
end