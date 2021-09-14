module ShopifyCli
  module ExceptionReporter
    autoload :PermissionController, "shopify-cli/exception_reporter/permission_controller"

    def self.report(error, _logs = nil, _api_key = nil, custom_metadata = {})
      return unless report_error?(error)

      return if ShopifyCli::Environment.development?
      return if !ShopifyCli::Environment.automatic_error_tracking_enabled? && !ExceptionReporter::PermissionController.can_send?

      ENV["BUGSNAG_DISABLE_AUTOCONFIGURE"] = "1"
      require "bugsnag"

      Bugsnag.configure do |config|
        config.logger.level = ::Logger::ERROR
        config.api_key = ShopifyCli::Constants::Bugsnag::API_KEY
        config.app_type = "shopify"
        config.project_root = File.expand_path("../../..", __FILE__)
        config.app_version = ShopifyCli::VERSION
        config.auto_capture_sessions = false
      end

      metadata = {}
      metadata.merge!(custom_metadata)
      Bugsnag.notify(error, metadata)
    end

    def self.report_error?(error)
      is_abort = error.is_a?(ShopifyCli::Abort) || error.is_a?(ShopifyCli::AbortSilent)
      !is_abort
    end
  end
end
