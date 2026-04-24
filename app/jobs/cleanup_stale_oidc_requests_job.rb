class CleanupStaleOidcRequestsJob < ApplicationJob
  queue_as :default

  def perform
    OidcRequest.delete_stale
  end
end
