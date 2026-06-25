# frozen_string_literal: true

# ============================================================================
# SiteConfig — DHero Boilerplate (PER-PROJECT — fill PLACEHOLDERs in Phase 1)
# ============================================================================
#
# Country/market profile(s). Single-market scrapers keep one entry; multi-market
# scrapers (e.g. snoonu QA/KW, yummy VE/PE/PA) add more and select via
# `ENV['country']`. Modeled on snoonu_qa/lib/site_config.rb.
#
# What to fill during discovery (Phase 1):
#   - base_url, api_host, country_code, currency, default lat/long
#   - dial_code (for phone formatting) and city_zones (lat/long bounding boxes)
#   - header builders + cookie/session bits the site requires
# ============================================================================

require 'cgi'
require 'json'

module SiteConfig
  PROFILES = {
    # PLACEHOLDER country key — duplicate this block per market.
    'PLACEHOLDER_COUNTRY' => {
      base_url:      'PLACEHOLDER_BASE_URL',       # e.g. 'https://snoonu.com'
      api_host:      'PLACEHOLDER_API_HOST',       # e.g. 'https://admin.snoonu.com'
      country_code:  'PLACEHOLDER_COUNTRY_ISO',    # 2-letter, e.g. 'QA'
      currency:      'PLACEHOLDER_CURRENCY',       # 3-letter ISO 4217, e.g. 'QAR'
      dial_code:     'PLACEHOLDER_DIAL_CODE',      # e.g. '974' (nil to disable phone normalize)
      default_city:  'PLACEHOLDER_DEFAULT_CITY',
      latitude:      'PLACEHOLDER_LAT',            # discovery/seed default coordinate
      longitude:     'PLACEHOLDER_LONG',
      # [name, min_lat, max_lat, min_lng, max_lng] — optional; powers city_from_coordinates
      city_zones:    []
    }
  }.freeze

  module_function

  def country
    (ENV['country'] || PROFILES.keys.first).to_s.strip.upcase
  end

  def profile
    PROFILES.fetch(country) { PROFILES.values.first }
  end

  def base_url;      profile[:base_url];      end
  def api_host;      profile[:api_host];      end
  def country_code;  profile[:country_code];  end
  def currency;      profile[:currency];      end
  def dial_code;     profile[:dial_code];     end
  def default_city;  profile[:default_city];  end
  def latitude;      profile[:latitude];      end
  def longitude;     profile[:longitude];     end
  def city_zones;    profile[:city_zones] || []; end
  def home_url;      "#{base_url}/";          end

  # ---- URL builders (fill the path patterns in Phase 1) -------------------
  def restaurant_url(slug)
    raise 'restaurant slug missing' if slug.to_s.strip.empty?
    "#{base_url}/PLACEHOLDER_RESTAURANT_PATH/#{slug}"
  end

  def listings_api_url(page_number)
    "#{api_host}/PLACEHOLDER_LISTINGS_ENDPOINT?Page=#{page_number.to_i}"
  end

  # ---- header builders ----------------------------------------------------
  def browser_headers(extra = {})
    {
      'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-US,en;q=0.9',
      'User-Agent'      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36'
    }.merge(extra)
  end

  # API requests must be standard fetch (browser fetch wraps JSON in HTML).
  def api_headers(extra = {})
    {
      'Accept'        => '*/*',
      'Content-Type'  => 'application/json',
      'Accept-Language' => 'en-US,en;q=0.9',
      'Origin'        => base_url,
      'Referer'       => home_url,
      'User-Agent'    => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36'
      # PLACEHOLDER: add geo headers (Latitude/Longitude), app-version, auth, etc.
    }.merge(extra)
  end
end
