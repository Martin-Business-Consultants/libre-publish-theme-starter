# frozen_string_literal: true

# The site as an app on a home screen (/site.webmanifest).
json.name starter_name
json.short_name starter_name.truncate(12, omission: "")
json.start_url "/"
json.display "standalone"
json.theme_color website_design(:accent)
json.background_color "#fbfcfb"
json.icons [{src: starter_favicon_href, sizes: "any", type: (starter_favicon_href.include?(".svg") ? "image/svg+xml" : "image/png")}]
