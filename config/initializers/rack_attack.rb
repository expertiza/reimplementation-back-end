# frozen_string_literal: true

# Rack::Attack middleware configuration for OIDC login rate limiting.
# Uses a dedicated MemoryStore in test so the null_store in test.rb doesn't
# interfere, and relies on Rails.cache (Redis) in all other environments.
if Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
else
  Rack::Attack.cache.store = Rails.cache
end

# ── Throttles ─────────────────────────────────────────────────────────────────

# Limit authorization initiation to 5 requests per minute per IP.
# This endpoint creates a DB row and triggers OIDC provider discovery, making
# it expensive and a prime target for abuse.
Rack::Attack.throttle("oidc/client-select/ip", limit: 5, period: 60) do |req|
  req.ip if req.post? && req.path == "/auth/client-select"
end

# Tighten the limit further per IP+username combination to prevent an attacker
# from targeting a specific account across retries.
Rack::Attack.throttle("oidc/client-select/ip+username", limit: 3, period: 60) do |req|
  if req.post? && req.path == "/auth/client-select"
    body = req.body.read
    req.body.rewind
    params = JSON.parse(body) rescue {}
    username = params["username"].to_s.strip
    "#{req.ip}:#{username}" unless username.empty?
  end
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
