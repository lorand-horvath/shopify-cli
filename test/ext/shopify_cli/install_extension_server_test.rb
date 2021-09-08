require "test_helper"
require_relative "../../../ext/shopify-cli/install_extension_server"

module ShopifyCli
  class InstallExtensionServerTest < Minitest::Test
    def test_installation
      stub_releases_request
      stub_executable_download

      target = File.join(Dir.mktmpdir, "shopify-extensions")

      InstallExtensionServer.call(
        platform: Platform.new({
          "host_os" => "darwin20.3.0",
          "host_cpu" => "x86_64"
        }),
        version: "v0.1.0",
        source: "shopify-extensions",
        target: target
      )

      assert File.file?(target)
      assert File.executable?(target)
      assert_match /Shopify Extensions Dummy/, `#{target}`
    end

    class PlatformTest < MiniTest::Test
      def test_recognizes_linux
        linux_vm = ruby_config(os: "linux-gnu", cpu: "x86_64")
        assert_equal "linux-amd64", Platform.new(linux_vm).to_s
      end

      def test_recognices_mac_os
        intel_mac = ruby_config(os: "darwin20.3.0", cpu: "x86_64")
        m1_mac = ruby_config(os: "darwin20.3.0", cpu: "arm64")

        assert_equal "darwin-amd64", Platform.new(intel_mac).to_s
        assert_equal "darwin-arm64", Platform.new(m1_mac).to_s
      end

      def test_recognices_windows
        windows_vm_64_bit = ruby_config(os: "mingw32", cpu: "x64")
        windows_vm_32_bit = ruby_config(os: "mingw32", cpu: "i686")
        assert_equal "windows-amd64", Platform.new(windows_vm_64_bit).to_s
        assert_equal "windows-386", Platform.new(windows_vm_32_bit).to_s
      end

      private

      def ruby_config(os:, cpu:)
        {
          "host_os" => os,
          "host_cpu" => cpu,
        }
      end
    end

    class AssetTest < MiniTest::Test
      def test_initialization
        asset = Asset.new(
          name: "shopify-extensions-v0.1.0-darwin-amd64.tar.gz",
          url: "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-amd64.tar.gz"
        )

        assert_equal "v0.1.0", asset.version
        assert_equal "darwin", asset.os
        assert_equal "amd64", asset.cpu
      end
    end

    def stub_releases_request
      stub_request(:get, "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases")
        .to_return(status: 200, body: <<~JSON)
        [
          {
            "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/49152028",
            "assets_url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/49152028/assets",
            "upload_url": "https://uploads.github.com/repos/Shopify/shopify-cli-extensions/releases/49152028/assets{?name,label}",
            "html_url": "https://github.com/Shopify/shopify-cli-extensions/releases/tag/v0.1.0",
            "id": 49152028,
            "author": {
              "login": "t6d",
              "id": 77060,
              "node_id": "MDQ6VXNlcjc3MDYw",
              "avatar_url": "https://avatars.githubusercontent.com/u/77060?v=4",
              "gravatar_id": "",
              "url": "https://api.github.com/users/t6d",
              "html_url": "https://github.com/t6d",
              "followers_url": "https://api.github.com/users/t6d/followers",
              "following_url": "https://api.github.com/users/t6d/following{/other_user}",
              "gists_url": "https://api.github.com/users/t6d/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/t6d/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/t6d/subscriptions",
              "organizations_url": "https://api.github.com/users/t6d/orgs",
              "repos_url": "https://api.github.com/users/t6d/repos",
              "events_url": "https://api.github.com/users/t6d/events{/privacy}",
              "received_events_url": "https://api.github.com/users/t6d/received_events",
              "type": "User",
              "site_admin": false
            },
            "node_id": "MDc6UmVsZWFzZTQ5MTUyMDI4",
            "tag_name": "v0.1.0",
            "target_commitish": "main",
            "name": "v0.1.0",
            "draft": false,
            "prerelease": true,
            "created_at": "2021-09-07T19:18:18Z",
            "published_at": "2021-09-07T19:28:55Z",
            "assets": [
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246360",
                "id": 44246360,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzYw",
                "name": "shopify-extensions-v0.1.0-darwin-amd64.tar.gz",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/gzip",
                "state": "uploaded",
                "size": 5072802,
                "download_count": 1,
                "created_at": "2021-09-07T19:29:43Z",
                "updated_at": "2021-09-07T19:29:44Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-amd64.tar.gz"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246361",
                "id": 44246361,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzYx",
                "name": "shopify-extensions-v0.1.0-darwin-amd64.tar.gz.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:44Z",
                "updated_at": "2021-09-07T19:29:45Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-amd64.tar.gz.md5"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246348",
                "id": 44246348,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzQ4",
                "name": "shopify-extensions-v0.1.0-darwin-arm64.tar.gz",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/gzip",
                "state": "uploaded",
                "size": 4844685,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:36Z",
                "updated_at": "2021-09-07T19:29:36Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-arm64.tar.gz"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246349",
                "id": 44246349,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzQ5",
                "name": "shopify-extensions-v0.1.0-darwin-arm64.tar.gz.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:36Z",
                "updated_at": "2021-09-07T19:29:36Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-arm64.tar.gz.md5"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246419",
                "id": 44246419,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2NDE5",
                "name": "shopify-extensions-v0.1.0-linux-386.tar.gz",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/gzip",
                "state": "uploaded",
                "size": 4929913,
                "download_count": 0,
                "created_at": "2021-09-07T19:30:38Z",
                "updated_at": "2021-09-07T19:30:39Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-linux-386.tar.gz"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246424",
                "id": 44246424,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2NDI0",
                "name": "shopify-extensions-v0.1.0-linux-386.tar.gz.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:30:39Z",
                "updated_at": "2021-09-07T19:30:39Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-linux-386.tar.gz.md5"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246341",
                "id": 44246341,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzQx",
                "name": "shopify-extensions-v0.1.0-linux-amd64.tar.gz",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/gzip",
                "state": "uploaded",
                "size": 5214886,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:30Z",
                "updated_at": "2021-09-07T19:29:30Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-linux-amd64.tar.gz"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246343",
                "id": 44246343,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzQz",
                "name": "shopify-extensions-v0.1.0-linux-amd64.tar.gz.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:31Z",
                "updated_at": "2021-09-07T19:29:31Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-linux-amd64.tar.gz.md5"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246350",
                "id": 44246350,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzUw",
                "name": "shopify-extensions-v0.1.0-windows-386.zip",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/zip",
                "state": "uploaded",
                "size": 4923804,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:37Z",
                "updated_at": "2021-09-07T19:29:37Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-windows-386.zip"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246352",
                "id": 44246352,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzUy",
                "name": "shopify-extensions-v0.1.0-windows-386.zip.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:37Z",
                "updated_at": "2021-09-07T19:29:38Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-windows-386.zip.md5"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246354",
                "id": 44246354,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzU0",
                "name": "shopify-extensions-v0.1.0-windows-amd64.zip",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "application/zip",
                "state": "uploaded",
                "size": 5120133,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:42Z",
                "updated_at": "2021-09-07T19:29:42Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-windows-amd64.zip"
              },
              {
                "url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/releases/assets/44246356",
                "id": 44246356,
                "node_id": "MDEyOlJlbGVhc2VBc3NldDQ0MjQ2MzU2",
                "name": "shopify-extensions-v0.1.0-windows-amd64.zip.md5",
                "label": "",
                "uploader": {
                  "login": "github-actions[bot]",
                  "id": 41898282,
                  "node_id": "MDM6Qm90NDE4OTgyODI=",
                  "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
                  "gravatar_id": "",
                  "url": "https://api.github.com/users/github-actions%5Bbot%5D",
                  "html_url": "https://github.com/apps/github-actions",
                  "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
                  "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
                  "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
                  "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
                  "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
                  "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
                  "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
                  "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
                  "type": "Bot",
                  "site_admin": false
                },
                "content_type": "text/plain",
                "state": "uploaded",
                "size": 33,
                "download_count": 0,
                "created_at": "2021-09-07T19:29:42Z",
                "updated_at": "2021-09-07T19:29:43Z",
                "browser_download_url": "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-windows-amd64.zip.md5"
              }
            ],
            "tarball_url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/tarball/v0.1.0",
            "zipball_url": "https://api.github.com/repos/Shopify/shopify-cli-extensions/zipball/v0.1.0",
            "body": "Pre-release of `shopify-extensions` for testing the integration with the Shopify CLI."
          }
        ]
      JSON
    end

    def stub_executable_download
      dummy_archive = load_dummy_archive

      stub_request(:get, "https://github.com/Shopify/shopify-cli-extensions/releases/download/v0.1.0/shopify-extensions-v0.1.0-darwin-amd64.tar.gz").
        to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/octet-stream",
            "Content-Disposition" => "attachment; filename=shopify-extensions_0.1.0_darwin_amd64.tar.gz",
            "Content-Length" => dummy_archive.size,
          },
          body: dummy_archive
        )
    end

    def load_dummy_archive
      path = File.expand_path("../../../fixtures/shopify-extensions.tar.gz", __FILE__)
      raise "Dummy archive not found: #{path}" unless File.file?(path)
      File.read(path)
    end
  end
end
