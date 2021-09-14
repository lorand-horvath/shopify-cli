module ShopifyCli
  module ExceptionReporter
    module PermissionController
      def self.can_send?(context: ShopifyCli::Context.new)
        # If the terminal is not interactive we can't prompt the user.
        return false unless ShopifyCli::Environment.interactive?

        if user_prompted?
          reporting_enabled?
        else
          prompt_user(context: context)
        end
      end

      def self.prompt_user(context:)
        enable_automatic_tracking = CLI::UI::Prompt.confirm(
          context.message("core.error_reporting.enable_automatic_reporting_prompt.message")
        )
        ShopifyCli::DB.set(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_PROMPTED => true)
        ShopifyCli::DB.set(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_ENABLED => enable_automatic_tracking)
        enable_automatic_tracking
      end

      def self.user_prompted?
        ShopifyCli::DB.exists?(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_PROMPTED)
      end

      def self.reporting_enabled?
        ShopifyCli::DB.get(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_ENABLED)
      end
    end
  end
end
