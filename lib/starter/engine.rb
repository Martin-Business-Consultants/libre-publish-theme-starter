# frozen_string_literal: true

module Starter
  # A theme is an engine like a plugin: its views and helpers join the app's,
  # its assets join Propshaft's load path (app/assets/*/starter), and it
  # registers with Website, which turns the public site on. Its scripts get an
  # importmap of their own (config/importmap.rb), so the admin's never reach a
  # visitor.
  class Engine < ::Rails::Engine
    initializer "starter.assets", before: "importmap" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    config.to_prepare do
      Cms::Plugins.register :starter, name: "Starter", version: Starter::VERSION,
        description: "The website, drawn from the CMS's content.", author: "You",
        enabled_by_default: true, requires: ">= 1.14"
      Website.register :starter, name: "Starter", version: Starter::VERSION,
        views: Starter::Engine.root.join("app/views"),
        importmap: Importmap::Map.new.draw(Starter::Engine.root.join("config/importmap.rb")),
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
