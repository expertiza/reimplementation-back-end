class CleanupStaleOidcRequestsJob < ApplicationJob
  queue_as :default

  def perform
    OidcRequest.stale.delete_all
  end
end
