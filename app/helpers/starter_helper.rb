# frozen_string_literal: true

# The theme's own vocabulary on top of the CMS's WebsiteHelper, what every
# theme needs: its files at the address the theme serves them from, the
# site's name and contact details, links, the title and favicon, and the
# forms. Each helper is named for the theme, so two themes linked side by
# side never shadow each other's.
module StarterHelper
  # Inline editing (the editor's preview) marks editable text with invisible
  # characters; an address or a phone number can't carry them.
  INLINE_EDIT_MARKS = [Website::InlineEdit::START, Website::InlineEdit::FINISH, *Website::InlineEdit::DIGITS].join.freeze
  # The attribution a form keeps, for the fields its form declares
  # (forms.js fills them from the visit).
  ATTRIBUTION = %w[utm_source utm_medium utm_campaign utm_term utm_content gclid fbclid msclkid landing_path referrer form_path].freeze
  DIGESTS = {} # rubocop:disable Style/MutableConstant

  # ── The theme's files ──

  # A file of the theme's ("site.css", "logo.png") at the address the theme
  # serves it from (Starter::AssetsController), with its digest so it can be
  # cached for good.
  def starter_asset_path(name)
    file = Starter::AssetsController.find(name) or raise ArgumentError, "the theme has no file #{name} (app/assets/*/starter, app/javascript/starter)"
    digest = Rails.env.production? ? (DIGESTS[name] ||= starter_digest(file)) : starter_digest(file)
    "/_starter/#{name}?v=#{digest}"
  end

  # The theme's scripts as ES modules (every .js in app/javascript/starter),
  # each preloaded, then site.js, which imports the rest. Its own importmap:
  # none of the admin's scripts reach a visitor.
  def starter_javascript_tags
    modules = Starter::AssetsController.files.keys.select { it.end_with?(".js") }.sort
    imports = modules.to_h { ["starter/#{it.delete_suffix(".js")}", starter_asset_path(it)] }
    nonce = content_security_policy_nonce
    safe_join([
      tag.script(ERB::Util.json_escape({imports:}.to_json).html_safe, type: "importmap", nonce:), # rubocop:disable Rails/OutputSafety -- our own paths, JSON-escaped
      *imports.values.map { tag.link(rel: "modulepreload", href: it, nonce:) },
      tag.script('import "starter/site"'.html_safe, type: "module", nonce:) # rubocop:disable Rails/OutputSafety -- a constant
    ], "\n")
  end

  # ── The site ──

  def starter_name = website_settings["title"].presence || "Home"

  # The page's <title>: its SEO title as written, else "<title> | <site>".
  def starter_seo_tags(record = nil, title: nil, **options)
    own = record.respond_to?(:seo) && record.seo.to_h["meta_title"].presence
    title ||= own || [record.try(:title).presence, starter_name].compact.uniq.join(" | ")
    website_seo_tags(record, title:, **options)
  end

  # The language of what's shown: the record's own locale, else the site's.
  def starter_locale(record = nil) = record.try(:locale).presence || website_settings["default_locale"].presence || "en"

  # Settings › Branding's favicon, else the theme's own.
  def starter_favicon_href
    id = Setting.get("branding")["favicon_id"].presence
    (id && website_image_url(id, width: 192)) || starter_asset_path("favicon.svg")
  end

  # Settings › Branding's logo, or nil (the header then shows the name).
  def starter_logo_id = Setting.get("branding")["logo_id"].presence

  # ── Links and contact details ──

  # An href from a link field ({kind, value}) or a plain string, without the
  # preview's inline-edit marks. Nothing for an empty or unsafe one.
  def starter_href(link)
    link = {"kind" => "url", "value" => link} if link.is_a?(String)
    link = link.to_h.stringify_keys
    website_href(link.merge("value" => starter_plain(link["value"])))
  end

  def starter_plain(text) = text.to_s.delete(INLINE_EDIT_MARKS).strip

  def starter_external?(href) = href.to_s.match?(%r{\Ahttps?://}) && !href.to_s.start_with?(website_url("/"))

  # A link that opens elsewhere in a new tab, and says so to a screen reader.
  def starter_link_to(label, href, **options)
    return if href.blank?
    return link_to(label, href, **options) unless starter_external?(href)

    link_to(href, target: "_blank", rel: "noopener", **options) { safe_join([label, tag.span(" (opens in a new tab)", class: "visually-hidden")]) }
  end

  # "tel:+15551234567" from however the number is written.
  def starter_tel(phone = website_settings["phone"])
    digits = starter_plain(phone).gsub(/[^\d+]/, "")
    "tel:#{digits}" if digits.present?
  end

  def starter_year = Time.current.year

  # A global's data, or nil when the site doesn't have it (a fresh site, or
  # one whose content hasn't been copied yet), so the layout still draws.
  def starter_global(slug)
    website_global(slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Whether the theme draws a collection's entries (website/entries/<slug>):
  # an entry of one it doesn't is a 404, so nothing links to it.
  def starter_draws?(collection_slug) = lookup_context.exists?("website/entries/#{collection_slug}", [], false)

  # ── Forms (the Forms plugin) ──

  # A published form by slug, or nil (no Forms plugin, or no such form).
  def starter_form(slug)
    return unless defined?(Form) && Cms::Plugins.enabled?(:forms)

    Form.find_by(slug: starter_plain(slug), status: "published")
  end

  # Where a form posts (the Forms plugin's public endpoint).
  def starter_form_action(form) = "/api/forms/#{form.slug}/submissions"

  # A choice field's options as the form defines them (a collection's
  # entries too, for one that lists them).
  def starter_choices(field) = defined?(FormChoices) ? FormChoices.for(field) : Array(field["options"]).select { it.is_a?(Hash) }

  # The spam check Settings › Forms has set up ({provider:, site_key:,
  # theme:}), or nil. The Forms plugin refuses a submission without its token
  # when one is, so a form that doesn't draw it never gets through.
  def starter_captcha = defined?(Forms) && Forms.respond_to?(:public_captcha) ? Forms.public_captcha : nil

  # A select for a choice field: a prompt, then the form's choices.
  def starter_select(field, id:, required:)
    prompt = tag.option(field["placeholder"].presence || "Choose…", value: "", disabled: required, selected: true)
    choices = starter_choices(field).map { tag.option(it["label"], value: it["value"]) }
    tag.select(safe_join([prompt, *choices]), id:, name: field["name"], required:)
  end

  # A field the form keeps for attribution: filled by the page, never shown.
  def starter_attribution?(field) = ATTRIBUTION.include?(field["name"])

  # The hidden attribution inputs, for the fields the form declares.
  def starter_attribution(form)
    safe_join(ATTRIBUTION.filter_map do |name|
      next unless form.fields.any? { it["name"] == name }

      tag.input(type: "hidden", name:, value: (name == "form_path") ? request.path : nil, data: {attribution: name})
    end)
  end

  private

  def starter_digest(file) = Digest::SHA1.file(file).hexdigest[0, 10]
end
