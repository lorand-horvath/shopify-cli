require_relative "./shopify_extensions"

File.write("Makefile", <<~MAKEFILE)
  .PHONY: clean

  clean: ;

  install: ;
MAKEFILE

ShopifyExtensions.install(
  version: "v0.1.0",
  source: "shopify-extensions",
  target: File.join(File.dirname(__FILE__), "shopify-extensions")
)
