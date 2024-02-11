# app/lib/json_web_token.rb
require 'openssl'

class JsonWebToken
  RSA_KEYS_FILE = 'rsa_keys.yml'.freeze

  if File.exist?(RSA_KEYS_FILE)
    rsa_keys = YAML.load_file(RSA_KEYS_FILE)
    RSA_PRIVATE_KEY = OpenSSL::PKey::RSA.new(rsa_keys['private_key'])
    RSA_PUBLIC_KEY = OpenSSL::PKey::RSA.new(rsa_keys['public_key'])
  else
    rsa_key = OpenSSL::PKey::RSA.generate(2048)
    RSA_PRIVATE_KEY = rsa_key
    RSA_PUBLIC_KEY = rsa_key.public_key
    File.write(RSA_KEYS_FILE, { 'private_key' => RSA_PRIVATE_KEY, 'public_key' => RSA_PUBLIC_KEY }.to_yaml)
  end

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, RSA_PRIVATE_KEY, 'RS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, RSA_PUBLIC_KEY, true, { algorithm: 'RS256' })[0]
    HashWithIndifferentAccess.new decoded
  end

  def self.public_key
    RSA_PUBLIC_KEY.to_s.gsub("-----BEGIN PUBLIC KEY-----\n", '').gsub("\n-----END PUBLIC KEY-----\n", '')
  end
end
