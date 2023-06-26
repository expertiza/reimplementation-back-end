if Rails.env === 'production'
  Rails.application.config.session_store :cookie_store, key: '_expertiza', domain: 'expertiza-api'
else
  Rails.application.config.session_store :cookie_store, key: '_expertiza'
end
