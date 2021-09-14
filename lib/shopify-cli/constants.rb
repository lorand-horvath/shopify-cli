module ShopifyCli
  module Constants
    module Bugsnag
      API_KEY = "773b0c801eb40c20d8928be5b7c739bd"
    end

    module StoreKeys
      AUTOMATIC_ERROR_REPORTING_PROMPTED = :automatic_error_reporting_prompted
      AUTOMATIC_ERROR_REPORTING_ENABLED = :automatic_error_reporting_enabled
    end

    module EnvironmentVariables
      DEVELOPMENT = "SHOPIFY_CLI_DEVELOPMENT"

      # When true, it enables automatic error tracking.
      AUTOMATIC_ERROR_REPORTING_ENABLED = "SHOPIFY_CLI_AUTOMATIC_ERROR_TRACKING_ENABLED"

      # When true the CLI points to a local instance of
      # the partners dashboard and identity.
      LOCAL_PARTNERS = "SHOPIFY_APP_CLI_LOCAL_PARTNERS"

      # When true the CLI points to a spin instance of spin
      SPIN_PARTNERS = "SHOPIFY_APP_CLI_SPIN_PARTNERS"

      SPIN_WORKSPACE = "SPIN_WORKSPACE"

      SPIN_NAMESPACE = "SPIN_NAMESPACE"

      SPIN_HOST = "SPIN_HOST"

      # Set to true when running tests.
      RUNNING_TESTS = "RUNNING_SHOPIFY_CLI_TESTS"
    end

    module Identity
      CLIENT_ID_DEV = "e5380e02-312a-7408-5718-e07017e9cf52"
      CLIENT_ID = "fbdb2649-e327-4907-8f67-908d24cfd7e3"
    end
  end
end
