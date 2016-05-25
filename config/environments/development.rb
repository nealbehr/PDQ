Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
ENV["SSL_CERT_FILE"] = "C:/RailsInstaller/Ruby2.1.0/lib/ruby/2.1.0/rubygems/ssl_certs/cacert.pem"
  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Set the api tokens
  config.after_initialize do
    ApiTokens.zillow_key = 'X1-ZWz19qut1tazuz_1fz14' # Brad's Key
    ApiTokens.google_key = "AIzaSyCElExJi84Csi1WwouNB1eBn3hKd40dSZ8" # Brad's Key
    ApiTokens.census_key = "e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac" # Same for prod and test
    ApiTokens.mls_key = "b49bd1d9d1932fc26ea257baf9395d26" # Same for prod and test
  end

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
