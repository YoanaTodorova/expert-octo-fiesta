class SearchesChannel < ApplicationCable::Channel
  def subscribed
    search = CachedSearch.find(params[:id])
    stream_for search
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
