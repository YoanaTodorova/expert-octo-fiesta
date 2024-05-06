require 'rails_helper'

RSpec.describe 'CachedSearch' do
  fixtures :cached_searches

  let(:instance) { cached_searches(:office) }

  before do
    allow(SearchesChannel).to receive(:broadcast_to).and_return(true)
  end

  describe '.notify_successful_collection_download' do
    subject { instance.notify_successful_collection_download }

    it 'broadcasts proper message on SearchesChannel' do
      subject

      expect(SearchesChannel).to have_received(:broadcast_to).with(instance, 'movies-collection-available')
    end
  end

  describe '.notify_unsuccessful_collection_download' do
    subject { instance.notify_unsuccessful_collection_download }

    it 'broadcasts proper message on SearchesChannel' do
      subject

      expect(SearchesChannel).to have_received(:broadcast_to).with(instance, 'movies-collection-fetch-failed')
    end
  end
end