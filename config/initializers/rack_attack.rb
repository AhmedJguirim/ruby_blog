# Throttling (per client IP). Puma runs as a single process with threads, so
# an in-process store is shared by every request; counters reset on restart.
# nginx has its own limit_req zones on top of this (docker/nginx/default.conf).
class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)
  Rack::Attack.enabled = false if Rails.env.test? && ENV["RACK_ATTACK_IN_TEST"].blank?

  WRITE_METHODS = %w[POST PUT PATCH DELETE].freeze

  def self.write?(req)
    WRITE_METHODS.include?(req.request_method)
  end

  # request params can be malformed; a bad body must not turn into a 500 here
  def self.form_param(req, *keys)
    req.params.dig(*keys).to_s.downcase.strip.presence
  rescue StandardError
    nil
  end

  # --- authentication -------------------------------------------------------
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end

  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    form_param(req, "user", "email") if req.post? && req.path == "/users/sign_in"
  end

  throttle("api-logins/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/api/v1/login"
  end

  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users"
  end

  throttle("password-resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users/password"
  end

  throttle("password-resets/email", limit: 3, period: 1.hour) do |req|
    form_param(req, "user", "email") if req.post? && req.path == "/users/password"
  end

  # --- content creation (posts, comments, criticisms, documents, votes) -------
  CONTENT_PATH = %r{\A(/api/v1)?/(articles|comments|criticisms)(/|\z)}

  throttle("content-writes/ip", limit: 20, period: 1.minute) do |req|
    req.ip if write?(req) && req.path.match?(CONTENT_PATH) && !req.path.match?(/(up|down)vote\z/)
  end

  throttle("votes/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.post? && req.path.match?(/(up|down)vote\z/)
  end

  # --- uploads ----------------------------------------------------------------
  throttle("uploads/ip", limit: 10, period: 1.minute) do |req|
    req.ip if write?(req) && req.media_type.to_s.start_with?("multipart/")
  end

  # --- search -------------------------------------------------------------------
  throttle("search/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.get? && (req.path == "/tags/search" || (req.path == "/articles" && req.params["tag"].present?))
  end

  # --- everything else ----------------------------------------------------------
  throttle("requests/ip", limit: 300, period: 1.minute) do |req|
    req.ip unless req.path == "/up" || req.path.start_with?("/assets/", "/packs/")
  end

  self.throttled_responder = lambda do |req|
    match = req.env["rack.attack.match_data"] || {}
    retry_after = match[:period].to_i
    headers = { "Retry-After" => retry_after.to_s }
    if req.path.start_with?("/api/")
      [429, headers.merge("Content-Type" => "application/json"), ['{"error":"Too many requests"}']]
    else
      [429, headers.merge("Content-Type" => "text/plain"), ["Too many requests. Please slow down and try again shortly.\n"]]
    end
  end
end
