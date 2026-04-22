class OidcConfig
  class ProviderNotFound < StandardError; end

  CONFIG_FILE = Rails.root.join("config", "oidc_providers.yml").freeze
  REQUIRED_KEYS = %w[display_name issuer client_id client_secret redirect_uri].freeze

  # Loads, parses, and validates the OIDC provider YAML file.
  # Memoized per process — call reload! to force a re-read.
  # Invalid providers are skipped with a warning rather than crashing the app.
  def self.providers
    @providers ||= begin
                     yaml = ERB.new(File.read(CONFIG_FILE)).result
                     parsed = YAML.safe_load(yaml, permitted_classes: [], aliases: true)

                     unless parsed.is_a?(Hash)
                       Rails.logger.warn(
                         "OIDC config ignored: expected top-level mapping in #{CONFIG_FILE}, got #{parsed.class}"
                       )
                       parsed = {}
                     end

                     providers = parsed["providers"]
                     unless providers.is_a?(Hash)
                       Rails.logger.warn(
                         "OIDC config ignored: expected 'providers' to be a mapping in #{CONFIG_FILE}, got #{providers.class}"
                       )
                       providers = {}
                     end

                     validate!(providers)
                   end
  end

  # Looks up a provider config by its key (e.g. "google-ncsu").
  # Raises ProviderNotFound if the key is not configured.
  def self.find(provider_key)
    providers.fetch(provider_key) do
      raise ProviderNotFound, "Unknown OIDC provider: #{provider_key}"
    end
  end

  # Returns the list of providers safe to expose to the frontend.
  # Only includes display information — never secrets or endpoint URLs.
  def self.public_list
    providers.map { |key, cfg| { id: key, name: cfg["display_name"] } }
  end

  # Clears the memoized config so the next call to `providers` re-reads the YAML file.
  # Primarily useful for tests and hot-reloading in development.
  def self.reload!
    @providers = nil
  end

  # Parses the provider's scopes string (whitespace or comma-separated) into an array.
  # Falls back to the default OIDC scopes if none are configured.
  def self.scopes_for(provider)
    raw = provider["scopes"].to_s.split(/[\s,]+/).reject(&:blank?)
    raw.presence || %w[openid email profile]
  end

  private

  # Removes providers missing any REQUIRED_KEYS and logs a warning for each.
  # Mutates the provided hash so that `providers` returns only valid entries.
  def self.validate!(providers)
    providers.reject! do |key, cfg|
      missing = REQUIRED_KEYS.select { |k| cfg[k].blank? }
      if missing.any?
        Rails.logger.warn("OIDC provider '#{key}' skipped: missing #{missing.join(', ')}")
        true
      end
    end
    providers
  end

  private_class_method :validate!
end