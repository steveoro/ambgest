Ambgest3::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  require 'ruport'                                  # Ruby Reportin Tool
  require 'ruport/acts_as_reportable'               # ActiveRecord data collection for Ruport

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  # Use a different cache store in production:
  #config.cache_store = :memory_store, { size: 64.megabytes }

  config.action_mailer.perform_deliveries = false
  # Use this to disable delivery errors, and bad email addresses will be ignored:
  config.action_mailer.raise_delivery_errors = false

  # [Steve, 20130716] mailer options used by Devise
  config.action_mailer.default_url_options = {
    :host => 'localhost:3000'
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Use a different path for precompiling development assets:
  config.assets.prefix = "/dev-assets"

  # Allow 'better_errors' gem to output stack-trace on TRUSTED_IP (beyond localhost),
  # launching the Rails server as:
  #
  # > TRUSTED_IP=192.168.0.xyz rails s
  #
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']
end
