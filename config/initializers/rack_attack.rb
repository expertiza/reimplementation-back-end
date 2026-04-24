# frozen_string_literal: true

# Rack::Attack middleware configuration for OIDC login rate limiting.
#
# Cache store strategy:
#   test/development — MemoryStore: always available, no Redis required.
#     test.rb sets Rails.cache to :null_store (counters would never accumulate),
#     and development uses :null_store by default, so we use MemoryStore directly.
#   production — Rails.cache (Redis): shared across requests within a process.
#     Note: configured with raise_errors: false in this app, so a Redis outage
#     will silently drop counters and cause throttles to fail open. Monitor
#     Redis availability accordingly.
Rack::Attack.cache.store = if Rails.env.production?
  Rails.cache
else
  ActiveSupport::Cache::MemoryStore.new
end

# ── Throttles ─────────────────────────────────────────────────────────────────

# Limit authorization initiation to 5 requests per minute per IP.
# This endpoint creates a DB row and triggers OIDC provider discovery, making
# it expensive and a prime target for abuse.
Rack::Attack.throttle("oidc/client-select/ip", limit: 5, period: 60) do |req|
  req.ip if req.post? && req.path == "/auth/client-select"
end

# Limit callback completions to 10 requests per minute per IP.
# Protects against code-reuse replay attempts and brute-force state guessing.
Rack::Attack.throttle("oidc/callback/ip", limit: 10, period: 60) do |req|
  req.ip if req.post? && req.path == "/auth/callback"
end

# ── Throttled response ─────────────────────────────────────────────────────────

# Return JSON-formatted 429 responses consistent across OidcLoginController.
Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env["rack.attack.match_data"]
  retry_after = match_data ? (match_data[:period] - (Time.now.to_i % match_data[:period])) : 60

  [
    429,
    {
      "Content-Type"  => "application/json",
      "Retry-After"   => retry_after.to_s
    },
    [{ error: "Rate limit exceeded. Try again later." }.to_json]
  ]
end
