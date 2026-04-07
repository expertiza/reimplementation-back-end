class OidcConfig
  class ProviderNotFound < StandardError; end

  CONFIG_FILE = Rails.root.join("config", "oidc_providers.yml").freeze

  def self.providers
    @providers ||= begin
                     yaml = ERB.new(File.read(CONFIG_FILE)).result
                     parsed = YAML.safe_load(yaml, permitted_classes: [], aliases: true)
                     providers_config = parsed&.fetch("providers", {})
                     validate!(providers_config || {})
                   end
  end

  def self.find(provider_key)
    providers.fetch(provider_key) do
      raise ProviderNotFound, "Unknown OIDC provider: #{provider_key}"
    end
  end

  def self.public_list
    providers.map { |key, cfg| provider_summary(key, cfg) }
  end

  def self.reload!
    @providers = nil
  end

  private

  REQUIRED_KEYS = %w[display_name issuer client_id client_secret redirect_uri scopes].freeze

  def self.validate!(providers)
    return {} if providers.blank?

    providers.each do |key, cfg|
      missing = REQUIRED_KEYS.select { |k| cfg[k].blank? }
      if missing.any?
        raise "OIDC provider '#{key}' is missing required config: #{missing.join(', ')}"
      end
    end
    providers
  end

  def self.provider_summary(key, cfg)
    { id: key, name: cfg["display_name"] }
  end
end