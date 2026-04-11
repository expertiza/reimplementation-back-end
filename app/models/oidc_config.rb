class OidcConfig
  class ProviderNotFound < StandardError; end

  CONFIG_FILE = Rails.root.join("config", "oidc_providers.yml").freeze
  DEFAULT_SCOPES = %i[openid email profile].freeze

  def self.providers
    @providers ||= begin
                     yaml = ERB.new(File.read(CONFIG_FILE)).result
                     parsed = YAML.safe_load(yaml, permitted_classes: [], aliases: true)
                     parsed = {} unless parsed.is_a?(Hash)
                     providers_config = parsed["providers"]
                     validate!(providers_config.is_a?(Hash) ? providers_config : {})
                   rescue Errno::ENOENT, Psych::SyntaxError => e
                     Rails.logger.error("OIDC config load failed: #{e.message}")
                     {}.freeze
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

  def self.scopes_for(provider)
    raw_scopes = provider["scopes"]

    scopes = case raw_scopes
             when String
               raw_scopes.split(/[\s,]+/).reject(&:blank?)
             when Array
               raw_scopes.map(&:to_s).reject(&:blank?)
             else
               []
             end

    scopes = DEFAULT_SCOPES if scopes.blank?
    scopes.map(&:to_sym)
  end

  private

  REQUIRED_KEYS = %w[display_name issuer client_id client_secret redirect_uri].freeze

  def self.validate!(providers)
    return {}.freeze if providers.blank?

    valid_providers = {}

    providers.each do |key, cfg|
      unless cfg.is_a?(Hash)
        Rails.logger.warn("OIDC provider '#{key}' skipped: invalid config format")
        next
      end

      missing = REQUIRED_KEYS.select { |k| cfg[k].blank? }
      if missing.any?
        Rails.logger.warn("OIDC provider '#{key}' skipped: missing #{missing.join(', ')}")
        next
      end

      valid_providers[key] = cfg.deep_dup.freeze
    end

    valid_providers.freeze
  end

  def self.provider_summary(key, cfg)
    { id: key, name: cfg["display_name"] }
  end
end