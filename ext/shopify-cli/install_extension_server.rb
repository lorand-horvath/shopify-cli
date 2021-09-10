require 'open-uri'
require 'json'
require 'zlib'
require 'rubygems'
require 'rubygems/package'

module ShopifyCli
  class InstallExtensionServer
    def self.call(platform: Platform.new, **args)
      new.call(platform: platform, **args)
    end

    def call(platform:, version:, source:, target:)
      releases
        .find { |release| release.version == version }
        .download(platform: platform, source: source, target: target)

      raise "Failed to install extension development server" unless File.executable?(target)
      raise "Failed to isntall the correct extension development server version" unless `#{target} version`.strip == version.strip
    end

    private

    def releases
      JSON.parse(URI.open(release_url).read).map(&Release)
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

    def download(platform:, source:, target:)
      assets
        .filter(&:binary?)
        .find { |asset| asset.os == platform.os && asset.cpu == platform.cpu }
        .download(source: source, target: target)
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

    def download(source:, target:)
      Dir.chdir(File.dirname(target)) do
        File.open(File.basename(target), "w") do |target_file|
          unpack(source, from: decompress(URI.open(url)), to: target_file)
        end
        File.chmod(0755, target)
      end
    end

    def binary?
      !!/(tar\.gz)|(zip)$/.match(name)
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

    def version
      name_without_extension.split("-")[-3]
    end

    private

    def decompress(archive)
      decoder = Zlib::GzipReader.new(archive)
      unzipped = StringIO.new(decoder.read)
      decoder.close
      unzipped
    end

    def unpack(name, from:, to:)
      Gem::Package::TarReader.new(from) do |tar|
        tar.each do |entry|
          next unless File.basename(entry.full_name) == name
          to.write(entry.read)
        end
      end
    end

    def name_without_extension
      if binary?
        File.basename(name, ".tar.gz")
      elsif checksum?
        File.basename(name, "_checksum.txt")
      else
        raise NotImplementedError, "Unknown file type"
      end
    end

    Platform = Struct.new(:ruby_config) do
      def initialize(ruby_config = RbConfig::CONFIG)
        super(ruby_config)
      end

      def to_s
        format("%{os}-%{cpu}", os: os, cpu: cpu)
      end

      def os
        case ruby_config.fetch('host_os')
        when /linux/
          "linux"
        when /darwin/
          "darwin"
        else
          "windows"
        end
      end

      def cpu
        case ruby_config.fetch('host_cpu')
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
