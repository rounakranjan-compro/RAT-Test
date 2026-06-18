require_relative "boot"
require "rails"
require "logger"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# config/application.rb
module RailsApp
  class Application < Rails::Application
    config.load_defaults 6.1
    config.api_only = true
    config.active_support.escape_html_entities_in_json = false

    config.eager_load_paths << Rails.root.join('app/lib')

    # Must be inserted BEFORE OmniAuth so session exists when OmniAuth runs
    config.middleware.insert_before 0, ActionDispatch::Cookies
    config.middleware.insert_before 0, ActionDispatch::Session::CookieStore,
      key: '_regression_session',
      same_site: :lax,
      secure: false   # true in production
  end
end
