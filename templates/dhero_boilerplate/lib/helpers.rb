# frozen_string_literal: true

# ============================================================================
# Helpers — DHero Boilerplate (request builders; fill PLACEHOLDERs in Phase 1)
# ============================================================================
#
# Centralizes how pages are enqueued so parsers stay readable and every request
# carries the right fetch settings. Modeled on snoonu_qa/lib/helpers.rb.
#
# API requests: keep fetch_type "standard" + custom_headers/no_default_headers
# (browser fetch returns HTML-wrapped content, not raw JSON).
# ============================================================================

require './lib/site_config'

# ---------------------------------------------------------------------------
# Standalone helpers — usable outside the Helpers class
# ---------------------------------------------------------------------------

# Convert nil/empty/sentinel strings to nil
def empty_to_nil(str)
  s = str.to_s.strip
  s.empty? || s == '{}' || s == '[]' || s == '.' ? nil : s
end

# Standard autorefetch — call after HTTP status check in every parser
def autorefetch(reason)
  puts "AUTO-REFETCH: #{reason}" if ENV['debug']
  if page['refetch_count'].to_i > 3
    limbo page['gid']
  else
    refetch page['gid']
  end
  finish
end

# ---------------------------------------------------------------------------
# Page-builder factory — all page queuing goes through Helpers class methods
# ---------------------------------------------------------------------------

class Helpers
  PRIORITY_LISTINGS   = 100
  PRIORITY_RESTAURANT = 50
  PRIORITY_MENU       = 20

  # Restaurant listing page (HTML or API). For geo seeding, pass lat/long in vars.
  def self.listings_page(page_number:, vars: {})
    {
      url:                SiteConfig.listings_api_url(page_number),
      page_type:          'listings',
      method:             'GET',
      fetch_type:         'standard',
      headers:            SiteConfig.api_headers,
      http2:              true,
      custom_headers:     true,
      no_default_headers: true,
      priority:           PRIORITY_LISTINGS,
      vars:               { 'page_number' => page_number }.merge(vars)
    }
  end

  # Restaurant detail page (HTML) — carries rank + geo vars forward for output.
  def self.restaurant_page(slug:, restaurant_name:, rank: nil, vars: {})
    {
      url:                SiteConfig.restaurant_url(slug),
      page_type:          'restaurant_details',
      method:             'GET',
      headers:            SiteConfig.browser_headers,
      http2:              true,
      custom_headers:     true,
      no_default_headers: true,
      priority:           PRIORITY_RESTAURANT,
      vars:               {
        'slug'            => slug,
        'restaurant_name' => restaurant_name,
        'rank_in_listing' => rank
      }.merge(vars)
    }
  end

  # Menu / products API page. POST body filled per the discovered endpoint.
  def self.menu_page(menu_id:, page_number: 1, vars: {})
    {
      url:                "#{SiteConfig.api_host}/PLACEHOLDER_MENU_ENDPOINT",
      page_type:          'menu',
      method:             'POST',
      fetch_type:         'standard',
      headers:            SiteConfig.api_headers,
      http2:              true,
      custom_headers:     true,
      no_default_headers: true,
      priority:           PRIORITY_MENU,
      body:               { menu_id: menu_id, page: page_number }.to_json,
      vars:               { 'menu_id' => menu_id, 'page_number' => page_number }.merge(vars)
    }
  end
end
