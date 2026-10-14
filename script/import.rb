# frozen_string_literal: true

# The old site's content, into this CMS: block types, collections, pages,
# globals. Run inside a Libre Publish checkout with the theme linked, as often
# as you like (everything is matched by slug or path and updated):
#
#   bin/rails runner themes/starter/script/import.rb
#
# Read the old site's content from where the migration left it (an export, a
# checkout, a JSON dump), shape it with Starter::Import (script/import/kit.rb),
# and keep every old URL: one that changes gets a redirect (Tools › Redirects).
# Then bin/rails starter:snapshot, and the theme's spec draws every page.
require_relative "import/kit"

module Starter
  module Import
    def self.run
      hero = block(:hero, {"heading" => "Lead with your strongest line.", "subheading" => "", "ctas" => []})
      page("home", title: "Home", blocks: [hero])
      global(:nav, {"items" => [{"label" => "Home", "link" => link("/")}]},
        fields: Global.find_by(slug: "nav")&.fields)
      puts "Imported."
    end
  end
end

Starter::Import.run
