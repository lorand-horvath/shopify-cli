# frozen_string_literal: true
require "project_types/theme/test_helper"

module Theme
  module Commands
    class PullTest < MiniTest::Test
      include TestHelpers::FakeUI

      def setup
        super

        @ctx = ShopifyCli::Context.new
        @command = Theme::Command::Pull.new(@ctx)

        @theme = stub(
          "Theme",
          id: 1234,
          name: "Test theme",
          shop: "test.myshopify.io",
        )
        @syncer = stub("Syncer", delay_errors!: nil, report_errors!: nil)
        @ignore_filter = mock("IgnoreFilter")
      end

      def test_pull_theme
        ShopifyCli::Theme::Theme.expects(:new)
          .with(@ctx, root: ".", id: 1234)
          .returns(@theme)

        ShopifyCli::Theme::IgnoreFilter.expects(:from_path).with(".").returns(@ignore_filter)

        ShopifyCli::Theme::Syncer.expects(:new)
          .with(@ctx, theme: @theme, ignore_filter: @ignore_filter)
          .returns(@syncer)

        @syncer.expects(:start_threads)
        @syncer.expects(:shutdown)

        @syncer.expects(:download_theme!).with(delete: true)
        @ctx.expects(:done)

        @command.options.flags[:theme_id] = 1234
        @command.call([], "pull")
      end

      def test_pull_pass_nodelete_to_syncer
        ShopifyCli::Theme::Theme.expects(:new)
          .with(@ctx, root: ".", id: 1234)
          .returns(@theme)

        ShopifyCli::Theme::IgnoreFilter.expects(:from_path).with(".").returns(@ignore_filter)

        ShopifyCli::Theme::Syncer.expects(:new)
          .with(@ctx, theme: @theme, ignore_filter: @ignore_filter)
          .returns(@syncer)

        @syncer.expects(:start_threads)
        @syncer.expects(:shutdown)

        @syncer.expects(:download_theme!).with(delete: false)

        @ctx.expects(:done)

        @command.options.flags[:theme_id] = 1234
        @command.options.flags[:nodelete] = true
        @command.call([], "pull")
      end

      def test_pull_with_ignores
        ShopifyCli::Theme::Theme.expects(:new)
          .with(@ctx, root: ".", id: 1234)
          .returns(@theme)

        ShopifyCli::Theme::IgnoreFilter.expects(:from_path).with(".").returns(@ignore_filter)
        @ignore_filter.expects(:add_patterns).with(["config/*"])

        ShopifyCli::Theme::Syncer.expects(:new)
          .with(@ctx, theme: @theme, ignore_filter: @ignore_filter)
          .returns(@syncer)

        @syncer.expects(:start_threads)
        @syncer.expects(:shutdown)

        @syncer.expects(:download_theme!).with(delete: true)

        @ctx.expects(:done)

        @command.options.flags[:theme_id] = 1234
        @command.options.flags[:ignores] = ["config/*"]
        @command.call([], "pull")
      end

      def test_pull_asks_to_select
        CLI::UI::Prompt.expects(:ask).returns(@theme)
        @ctx.expects(:done)

        @syncer.expects(:download_theme!).with(delete: true)

        ShopifyCli::Theme::IgnoreFilter.expects(:from_path).with(".").returns(@ignore_filter)

        ShopifyCli::Theme::Syncer.expects(:new)
          .with(@ctx, theme: @theme, ignore_filter: @ignore_filter)
          .returns(@syncer)

        @syncer.expects(:start_threads)
        @syncer.expects(:shutdown)

        @command.call([], "pull")
      end
    end
  end
end
