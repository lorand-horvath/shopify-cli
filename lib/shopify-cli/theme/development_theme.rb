# frozen_string_literal: true
require_relative "theme"

require "socket"
require "securerandom"

module ShopifyCli
  module Theme
    API_NAME_LIMIT = 50

    class DevelopmentTheme < Theme
      def id
        ShopifyCli::DB.get(:development_theme_id)
      end

      def name
        existing_name = ShopifyCli::DB.get(:development_theme_name)
        # Up to version 2.3.0 (included) generated names stored locally
        # could have more than 50 characters and the API rejected them.
        # This code ensures we update the name for those users to ensure
        # the name stays under the limit.
        if existing_name.nil? || existing_name.length > API_NAME_LIMIT
          generate_theme_name
        else
          existing_name
        end
      end

      def role
        "development"
      end

      def ensure_exists!
        if exists?
          @ctx.debug("Using temporary development theme: ##{id} #{name}")
        else
          create
          @ctx.debug("Created temporary development theme: #{@id}")
          ShopifyCli::DB.set(development_theme_id: @id)
        end
      end

      def exists?
        return false unless id

        ShopifyCli::AdminAPI.rest_request(
          @ctx,
          shop: shop,
          path: "themes/#{id}.json",
          api_version: "unstable",
        )
      rescue ShopifyCli::API::APIRequestNotFoundError
        false
      end

      def delete
        super if exists?
        ShopifyCli::DB.del(:development_theme_id) if ShopifyCli::DB.exists?(:development_theme_id)
        ShopifyCli::DB.del(:development_theme_name) if ShopifyCli::DB.exists?(:development_theme_name)
      end

      def self.delete(ctx)
        new(ctx).delete
      end

      private

      def generate_theme_name
        hostname = Socket.gethostname.split(".").shift
        hash = SecureRandom.hex(3)

        theme_name = "Development ()"
        hostname_character_limit = API_NAME_LIMIT - theme_name.length - hash.length - 1
        identifier = "#{hash}-#{hostname[0, hostname_character_limit]}"
        theme_name = "Development (#{identifier})"

        ShopifyCli::DB.set(development_theme_name: theme_name)

        theme_name
      end
    end
  end
end
