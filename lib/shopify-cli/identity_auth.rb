require "base64"
require "digest"
require "json"
require "net/http"
require "securerandom"
require "openssl"
require "shopify_cli"
require "uri"
require "webrick"

module ShopifyCli
  class IdentityAuth
    include SmartProperties

    autoload :Servlet, "shopify-cli/identity_auth/servlet"

    class Error < StandardError; end
    class Timeout < StandardError; end
    LocalRequest = Struct.new(:method, :path, :query, :protocol)

    DEFAULT_PORT = 3456
    REDIRECT_HOST = "http://127.0.0.1:#{DEFAULT_PORT}"

    APPLICATION_SCOPES = {
      "shopify" => %w[https://api.shopify.com/auth/shop.admin.graphql https://api.shopify.com/auth/shop.admin.themes https://api.shopify.com/auth/partners.collaborator-relationships.readonly],
      "storefront_renderer_production" => %w[https://api.shopify.com/auth/shop.storefront-renderer.devtools],
      "partners" => %w[https://api.shopify.com/auth/partners.app.cli.access],
    }

    APPLICATION_CLIENT_IDS = {
      "shopify" => "7ee65a63608843c577db8b23c4d7316ea0a01bd2f7594f8a9c06ea668c1b775c",
      "storefront_renderer_production" => "ee139b3d-5861-4d45-b387-1bc3ada7811c",
      "partners" => "271e16d403dfa18082ffb3d197bd2b5f4479c3fc32736d69296829cbb28d41a6",
    }

    DEV_APPLICATION_CLIENT_IDS = {
      "shopify" => "e92482cebb9bfb9fb5a0199cc770fde3de6c8d16b798ee73e36c9d815e070e52",
      "storefront_renderer_production" => "46f603de-894f-488d-9471-5b721280ff49",
      "partners" => "df89d73339ac3c6c5f0a98d9ca93260763e384d51d6038da129889c308973978",
    }

    EXCHANGE_TOKENS = APPLICATION_SCOPES.keys.map do |key|
      "#{key}_exchange_token".to_sym
    end

    IDENTITY_ACCESS_TOKENS = %i[
      identity_access_token
      identity_refresh_token
    ]

    property! :ctx
    property :store, default: -> { ShopifyCli::DB.new }
    property :state_token, accepts: String, default: SecureRandom.hex(30)
    property :code_verifier, accepts: String, default: SecureRandom.hex(30)

    attr_accessor :response_query

    def authenticate
      return if refresh_exchange_tokens || refresh_access_tokens

      initiate_authentication

      begin
        request_access_token(code: receive_access_code)
      rescue IdentityAuth::Timeout => e
        ctx.abort(e.message)
      end
      request_exchange_tokens
    end

    def reauthenticate
      return if refresh_exchange_tokens || refresh_access_tokens
      ctx.abort(ctx.message("core.identity_auth.error.reauthenticate", ShopifyCli::TOOL_NAME))
    end

    def code_challenge
      @code_challenge ||= Base64.urlsafe_encode64(
        OpenSSL::Digest::SHA256.digest(code_verifier),
        padding: false,
      )
    end

    def server
      @server ||= begin
        server = WEBrick::HTTPServer.new(
          Port: DEFAULT_PORT,
          Logger: WEBrick::Log.new(File.open(File::NULL, "w")),
          AccessLog: [],
        )
        server.mount("/", Servlet, self, state_token)
        server
      end
    end

    def self.delete_tokens_and_keys
      ShopifyCli::DB.del(*IDENTITY_ACCESS_TOKENS)
      ShopifyCli::DB.del(*EXCHANGE_TOKENS)
    end

    private

    def initiate_authentication
      @server_thread = Thread.new { server.start }
      params = {
        client_id: client_id,
        scope: scopes(APPLICATION_SCOPES.values.flatten),
        redirect_uri: REDIRECT_HOST,
        state: state_token,
        response_type: :code,
      }
      params.merge!(challange_params)
      uri = URI.parse("#{auth_url}/authorize")
      uri.query = URI.encode_www_form(params)
      open_browser_authentication(uri)
    end

    def open_browser_authentication(uri)
      ctx.open_browser_url!(uri)
    end

    def receive_access_code
      @access_code ||= begin
        @server_thread.join(240)
        raise Timeout, ctx.message("core.identity_auth.error.timeout") if response_query.nil?
        raise Error, response_query["error_description"] unless response_query["error"].nil?
        response_query["code"]
      end
    end

    def request_access_token(code:)
      resp = post_token_request(
        grant_type: :authorization_code,
        code: code,
        redirect_uri: REDIRECT_HOST,
        client_id: client_id,
        code_verifier: code_verifier,
      )
      store.set(
        identity_access_token: resp["access_token"],
        identity_refresh_token: resp["refresh_token"],
      )
    end

    def refresh_access_tokens
      return false unless IDENTITY_ACCESS_TOKENS.all? { |key| store.exists?(key) }

      resp = post_token_request(
        grant_type: :refresh_token,
        access_token: store.get(:identity_access_token),
        refresh_token: store.get(:identity_refresh_token),
        client_id: client_id,
      )
      store.set(
        identity_access_token: resp["access_token"],
        identity_refresh_token: resp["refresh_token"],
      )

      # Need to refresh the exchange token on successful access token refresh
      request_exchange_tokens

      true
    rescue
      store.del(*IDENTITY_ACCESS_TOKENS)
      false
    end

    def refresh_exchange_tokens
      return false unless EXCHANGE_TOKENS.all? { |key| store.exists?(key) }

      request_exchange_tokens

      true
    rescue
      store.del(*EXCHANGE_TOKENS)
      false
    end

    def request_exchange_tokens
      APPLICATION_SCOPES.each do |key, scopes|
        request_exchange_token(key, client_id_for_application(key), scopes)
      end
    end

    def request_exchange_token(name, audience, additional_scopes)
      return if name == "shopify" && !store.exists?(:shop)

      params = {
        grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
        requested_token_type: "urn:ietf:params:oauth:token-type:access_token",
        subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
        client_id: client_id,
        audience: audience,
        scope: scopes(additional_scopes),
        subject_token: store.get(:identity_access_token),
      }.tap do |result|
        if name == "shopify"
          result[:destination] = "https://#{store.get(:shop)}/admin"
        end
      end
      # ctx.debug(params)
      resp = post_token_request(params)
      store.set("#{name}_exchange_token".to_sym => resp["access_token"])
      ctx.debug("#{name}_exchange_token: " + resp["access_token"])
    end

    def post_token_request(params)
      post_request("/token", params)
    end

    def post_request(endpoint, params)
      uri = URI.parse("#{auth_url}#{endpoint}")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.path)
      request["User-Agent"] = "Shopify CLI #{::ShopifyCli::VERSION}"
      request.body = URI.encode_www_form(params)
      res = https.request(request)
      unless res.is_a?(Net::HTTPSuccess)
        error_msg = JSON.parse(res.body)["error_description"]
        shop = store.get(:shop)
        if error_msg.include?("destination")
          store.del(:shop)
          ctx.abort(ctx.message("core.identity_auth.error.invalid_destination", shop))
        end
        raise Error, error_msg
      end
      JSON.parse(res.body)
    end

    def challange_params
      {
        code_challenge: code_challenge,
        code_challenge_method: "S256",
      }
    end

    def auth_url
      if Environment.use_local_partners_instance?
        "https://identity.myshopify.io/oauth"
      elsif Environment.use_spin_partners_instance?
        "https://identity.#{Environment.spin_url}/oauth"
      else
        "https://accounts.shopify.com/oauth"
      end
    end

    def client_id_for_application(application_name)
      client_ids = if Environment.use_local_partners_instance? || Environment.use_spin_partners_instance?
        DEV_APPLICATION_CLIENT_IDS
      else
        APPLICATION_CLIENT_IDS
      end

      client_ids[application_name]
    end

    def scopes(additional_scopes = [])
      (["openid"] + additional_scopes).tap do |result|
        result << "employee" if ShopifyCli::Shopifolk.acting_as_shopify_organization?
      end.join(" ")
    end

    def client_id
      if Environment.use_local_partners_instance? || Environment.use_spin_partners_instance?
        Constants::Identity::CLIENT_ID_DEV
      else
        # In the future we might want to use Identity's dynamic
        # registration. To migrate to a dynamic client ID we
        # need to refactor some code that relies on a static
        # value for the client
        Constants::Identity::CLIENT_ID
      end
    end
  end
end
