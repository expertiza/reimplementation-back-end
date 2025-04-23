class Rack::Attack
  # Use memory store for rate limiting
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Allow all requests from localhost
  safelist('allow-localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Throttle all requests by IP (60 requests per minute)
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle login attempts by IP address
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by user name
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins:#{req.params['user_name']}"
  throttle('logins/username', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.params['user_name'].to_s.downcase
    end
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      req.path == '/login' && req.post? && req.params['user_name'].present?
    end
  end

  # Return rate limit info in response headers
  Rack::Attack.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_data']
    if match_data[:request].path == '/login'
      [
        429, # status
        { 'Content-Type' => 'application/json' }, # headers
        [{ error: 'Rate limit exceeded. Try again later.' }.to_json] # body
      ]
    else
      [
        429, # status
        { 'Content-Type' => 'application/json' }, # headers
        [{ error: 'Rate limit exceeded. Try again later.' }.to_json] # body
      ]
    end
  end
end 