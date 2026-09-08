require_relative "boot"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)

module OutpatientPortfolio
  class Application < Rails::Application
    # Rails起動時の共通設定。環境・DB・セッションの土台であり、画面処理は置かない。
    config.load_defaults 8.1
    # This unauthenticated prototype must not be deployed.
    raise "Only development/test environments are supported" unless Rails.env.development? || Rails.env.test?
    config.time_zone = "Tokyo"
    config.active_record.schema_format = :ruby
    config.hosts = ["localhost", "127.0.0.1"]
    config.hosts << "www.example.com" if Rails.env.test?
    config.filter_parameters += %i[patient last_name first_name last_name_kana first_name_kana birth_date]
    config.session_store :cookie_store, key: "_outpatient_portfolio", same_site: :strict, httponly: true
    config.action_controller.forgery_protection_origin_check = true
    # Keep the non-secret SQLite configuration tracked under a distinct name.
    config.paths["config/database"] = "config/database.example.yml"
  end
end
