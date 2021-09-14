require "test_helper"

module ShopifyCli
  module ExceptionReporter
    class PermissionControllerTest < MiniTest::Test
      def setup
        super
        @context = TestHelpers::FakeContext.new
      end

      def test_can_send_returns_false_when_the_environment_is_not_interactive
        # Given
        ShopifyCli::Environment.expects(:interactive?).returns(false)

        # When
        got = PermissionController.can_send?(context: @context)

        # Then
        refute got
      end

      def test_can_send_returns_true_when_the_user_was_already_prompted_and_they_enabled_it
        # Given
        ShopifyCli::Environment.expects(:interactive?).returns(true)
        ShopifyCli::DB.expects(:exists?)
          .with(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_PROMPTED)
          .returns(true)
        ShopifyCli::DB.expects(:get)
          .with(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_ENABLED)
          .returns(true)

        # When
        got = PermissionController.can_send?(context: @context)

        # Then
        assert got
      end

      def test_can_send_stores_and_returns_the_value_selected_by_the_user
        # Given
        ShopifyCli::Environment.expects(:interactive?).returns(true)
        ShopifyCli::DB.expects(:exists?)
          .with(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_PROMPTED)
          .returns(false)
        ShopifyCli::DB.expects(:set)
          .with(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_PROMPTED => true)
        ShopifyCli::DB.expects(:set)
          .with(Constants::StoreKeys::AUTOMATIC_ERROR_REPORTING_ENABLED => false)
        CLI::UI::Prompt.expects(:confirm).returns(false)

        # When
        got = PermissionController.can_send?(context: @context)

        # Then
        refute got
      end
    end
  end
end
