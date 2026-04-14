class OidcConfig
  class ProviderNotFound < StandardError; end

  CONFIG_FILE = Rails.root.join("config", "oidc_providers.yml").freeze
  REQUIRED_KEYS = %w[display_name issuer client_id client_secret redirect_uri].freeze

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

  def self.find(provider_key)
    providers.fetch(provider_key) do
      raise ProviderNotFound, "Unknown OIDC provider: #{provider_key}"
    end
  end

  def self.public_list
    providers.map { |key, cfg| { id: key, name: cfg["display_name"] } }
  end

  def self.reload!
    @providers = nil
  end

  def self.scopes_for(provider)
    raw = provider["scopes"].to_s.split(/[\s,]+/).reject(&:blank?)
    raw.presence || %w[openid email profile]
  end

  private

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