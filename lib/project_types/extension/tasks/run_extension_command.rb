
# frozen_string_literal: true
require "shopify_cli"

module Extension
  module Tasks
    class RunExtensionCommand < ShopifyCli::Task
      include SmartProperties

      SUPPORTED_EXTENSION_TYPES = [
        "checkout_ui_extension",
      ]

      SUPPORTED_COMMANDS = [
        "create",
        "build",
      ]

      property! :root_dir, accepts: String
      property! :template, accepts: Models::ServerConfig::Development::VALID_TEMPLATES
      property! :type, accepts: SUPPORTED_EXTENSION_TYPES
      property! :command, accepts: SUPPORTED_COMMANDS

      def call
        ShopifyCli::Result
          .call(&method(:build_extension))
          .then(&method(:build_server_config))
          .then(&method(:run_command))
          .unwrap { |error| raise error }
      end

      private

      def build_extension
        Models::ServerConfig::Extension.build(
          template: template,
          type: type,
          root_dir: root_dir,
        )
      end

      def build_server_config(extension)
        Models::ServerConfig::Root.new(extensions: [extension])
      end

      def run_command(server_config)
        case command
        when "create"
          Models::DevelopmentServer.new.create(server_config)
        end
      end
    end
  end
end
