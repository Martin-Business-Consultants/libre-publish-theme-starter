# frozen_string_literal: true

module Starter
  # A theme is an engine like a plugin: its views and helpers join the app's,
  # and it registers with Website, which turns the public site on. Its files
  # are served by the theme itself (Starter::AssetsController), so it works
  # however it was installed; its scripts get an importmap of their own
  # (the theme helper's starter_javascript_tags), so the admin's never reach a
  # visitor.
  class Engine < ::Rails::Engine
    # The theme's files, ahead of the website's catch-all.
    initializer "starter.routes" do |app|
      app.routes.append do
        get "_starter/*path", to: "starter/assets#show", format: false, as: :starter_asset
      end
    end

    config.to_prepare do
      # A plugin too, so Settings › Plugins installs it from its GitHub
      # release, updates it, and switches the site on and off.
      Cms::Plugins.register :starter, name: "Starter", version: Starter::VERSION,
        description: "The website, drawn from the CMS's content: switch it off and the CMS is headless.",
        author: "You", enabled_by_default: true, requires: ">= 1.33",
        homepage: "https://github.com/Martin-Business-Consultants/#{"starter".tr("_", "-")}-theme"
      # Block types the theme draws beyond the core's, installed the first
      # time it's switched on (an existing block type is left as it is).
      Cms::Plugins.block_types :starter, Starter::BLOCK_TYPES
      Website.register :starter, name: "Starter", version: Starter::VERSION,
        views: Starter::Engine.root.join("app/views"),
        # What an editor can change in Settings › Themes › Customize; the
        # stylesheet reads them as --design-accent and the rest.
        design: [
          {name: "accent", label: "Accent color", type: "color", default: "#2f6b4f"},
          {name: "heading_font", label: "Headings", type: "select", default: "serif",
           options: {"serif" => "Georgia, 'Times New Roman', serif", "sans" => "ui-sans-serif, system-ui, sans-serif"}},
          {name: "radius", label: "Corners", type: "select", default: "soft",
           options: {"square" => "0", "soft" => "10px", "round" => "22px"}}
        ]
    end
  end
end
