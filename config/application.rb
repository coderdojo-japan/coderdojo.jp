require_relative "boot"

require "rails/all"

# FIXME: The process of requiring the exceptions_app from rambulance is being loaded at an unexpected timing? So we're requiring it manually.
# Problematic code section: https://github.com/yuki24/rambulance/blob/v3.0.0/lib/rambulance/railtie.rb#L5
# Ref: https://github.com/yuki24/rambulance/issues/67#issuecomment-1945292833
require 'rambulance/exceptions_app'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoderdojoJp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Timezone
    config.time_zone = 'Asia/Tokyo'

    # Default I18n locale
    config.i18n.default_locale = :ja
  end
end
