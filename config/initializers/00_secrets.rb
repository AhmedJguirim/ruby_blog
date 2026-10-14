# Secrets come from the environment (see .env.example). The encrypted
# credentials file is only a fallback for local development.
Rails.application.config.x.jwt_secret =
  ENV["JWT_SECRET_KEY"].presence || Rails.application.credentials.dig(:jwt, :secret_key)

# Refuse to boot in production with missing, short or placeholder secrets.
# (The image build sets SECRET_KEY_BASE_DUMMY while precompiling assets.)
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  %w[SECRET_KEY_BASE JWT_SECRET_KEY].each do |name|
    value = ENV[name].to_s
    if value.length < 32 || value.match?(/change_?me|placeholder|replace_?me/i)
      raise "#{name} is missing, shorter than 32 characters or still a placeholder. " \
            "Generate real values with scripts/init-env.sh."
    end
  end

  unless ENV["APP_URL"].to_s.match?(%r{\Ahttps?://[^/\s]+\z})
    raise "APP_URL must look like https://blog.example.com (no path)."
  end
end
