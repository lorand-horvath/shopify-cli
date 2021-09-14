require "rbconfig"
require "open-uri"
require "json"
require "zlib"
require "rubygems"
require "rubygems/package"
require "open3"

module ShopifyExtensions
  class InstallationError < RuntimeError
    def self.not_executable
      new("Failed to install shopify-extensions")
    end

    def self.incorrect_version
      new("Failed to install the correct version of shopify-extensions")
    end

    def self.release_not_found
      new("Release not found")
    end
  end

  def self.install(**args)
    Install.call(**args)
  end

  class Install
    def self.call(platform: Platform.new, **args)
      new.call(platform: platform, **args)
    end

    def call(platform:, version:, target:)
      target = platform.format_path(target)

      releases
        .find { |release| release.version == version }
        .tap { |release| raise InstallationError.release_not_found unless release }
        .download(platform: platform, target: target)

      raise InstallationError.not_executable unless File.executable?(target)

      installed_server_version, _ = Open3.capture2(target, "version")
      raise InstallationError.incorrect_version unless installed_server_version.strip == version.strip
    end

    private

    def releases
      JSON.parse(URI.parse(release_url).open.read).map(&Release)
    end

    def release_url
      format(
        "https://api.github.com/repos/%{owner}/%{repo}/releases",
        owner: "Shopify",
        repo: "shopify-cli-extensions"
      )
    end
  end

  Release = Struct.new(:version, :assets, keyword_init: true) do
    def self.to_proc
      ->(release_data) do
        new(
          version: release_data.fetch("tag_name"),
          assets: release_data.fetch("assets").map(&Asset)
        )
      end
    end

    def download(platform:, target:)
      assets
        .filter(&:binary?)
        .find { |asset| asset.os == platform.os && asset.cpu == platform.cpu }
        .download(target: target)
    end
  end

  Asset = Struct.new(:name, :url, keyword_init: true) do
    def self.to_proc
      ->(asset_data) do
        new(
          name: asset_data.fetch("name"),
          url: asset_data.fetch("browser_download_url")
        )
      end
    end

    def download(target:)
      Dir.chdir(File.dirname(target)) do
        File.open(File.basename(target), "w") do |target_file|
          decompress(URI.parse(url).open, target_file)
        end
        File.chmod(0755, target)
      end
    end

    def binary?
      !!/\.gz$/.match(name)
    end

    def checksum?
      !!/\.md5$/.match(name)
    end

    def os
      name_without_extension.split("-")[-2]
    end

    def cpu
      name_without_extension.split("-")[-1]
    end

    private

    def decompress(source, target)
      zlib = Zlib::GzipReader.new(source)
      target << zlib.read
    ensure
      zlib.close
    end

    def name_without_extension
      if binary?
        File.basename(File.basename(name, ".gz"), ".exe")
      elsif checksum?
        File.basename(File.basename(name, ".md5"), ".exe")
      else
        raise NotImplementedError, "Unknown file type"
      end
    end

    Platform = Struct.new(:ruby_config) do
      def initialize(ruby_config = RbConfig::CONFIG)
        super(ruby_config)
      end

      def format_path(path)
        case os
        when "windows"
          File.extname(path) != ".exe" ? path + ".exe" : path
        else
          path
        end
      end

      def to_s
        format("%{os}-%{cpu}", os: os, cpu: cpu)
      end

      def os
        case ruby_config.fetch("host_os")
        when /linux/
          "linux"
        when /darwin/
          "darwin"
        else
          "windows"
        end
      end

      def cpu
        case ruby_config.fetch("host_cpu")
        when /arm.*64/
          "arm64"
        when /64/
          "amd64"
        else
          "386"
        end
      end
    end
  end
end
