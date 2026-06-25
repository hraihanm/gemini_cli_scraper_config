# frozen_string_literal: true

# ============================================================================
# Seeder - DHero Boilerplate
# ============================================================================
#
# Seed the initial page(s) that start the pipeline. The right strategy is chosen
# in Phase 1 (discovery-state.json.seeding.strategy) — most dhero sources are
# API-driven (geo/h3/city/session), NOT a crawlable URL listing.
#
# Pick ONE strategy below, uncomment it, and fill PLACEHOLDERs. See
# docs/workflows/phases/dhero-seeding-strategies.md for worked examples.
#
# DATAHEN v3: TOP-LEVEL SCRIPT. `pages` is pre-defined — never declare it.
# ============================================================================

require './lib/headers'
require './lib/helpers'
require './lib/site_config'

# ---------------------------------------------------------------------------
# Strategy: url_listings (HTML) — a real paginated restaurant list page.
# ---------------------------------------------------------------------------
pages << {
  url:        'PLACEHOLDER_HOMEPAGE_URL',
  page_type:  'listings',
  method:     'GET',
  fetch_type: 'PLACEHOLDER_FETCH_TYPE',   # 'standard' or 'browser'
  headers:    ReqHeaders::MINIMAL_HEADERS,
  priority:   100,
  vars:       { 'page_number' => 1 }
}

# ---------------------------------------------------------------------------
# Strategy: geo_grid — one listings request per lat/long row (totersapp/mrsool).
# Put coordinates in input/geo.csv with headers: city,lat,long
# ---------------------------------------------------------------------------
# require 'csv'
# CSV.foreach('./input/geo.csv', headers: true) do |row|
#   pages << Helpers.listings_page(
#     page_number: 1,
#     vars: {
#       'city'       => row['city'],
#       'input_lat'  => row['lat'].to_f,
#       'input_long' => row['long'].to_f
#     }
#   )
#   # NOTE: build the geo URL inside Helpers.listings_page / SiteConfig from these vars.
# end

# ---------------------------------------------------------------------------
# Strategy: h3_hexagon — city → H3 cell id, one request per cell (lezzoo).
# ---------------------------------------------------------------------------
# CITY_HEX = {
#   'Erbil' => 'PLACEHOLDER_H3', 'Baghdad' => 'PLACEHOLDER_H3',  # ...
# }
# CITY_HEX.each do |city, hex|
#   pages << {
#     url:       "PLACEHOLDER_WIDGETS_ENDPOINT?city=#{city}&hexagonId=#{hex}",
#     page_type: 'listings',           # or an 'init' page that fans out widgets
#     headers:   ReqHeaders::MINIMAL_HEADERS,
#     vars:      { 'city' => city, 'hexagonId' => hex }
#   }
# end

# ---------------------------------------------------------------------------
# Strategy: city_list / neighborhood_list — iterate an id list (talabatey/jahez).
# ---------------------------------------------------------------------------
# CITIES = [{ 'id' => 1, 'name' => 'PLACEHOLDER' }]
# CITIES.each do |c|
#   pages << Helpers.listings_page(page_number: 1, vars: { 'city' => c['name'], 'city_id' => c['id'] })
# end

# ---------------------------------------------------------------------------
# Strategy: session_bootstrap — mint token / set location first, then chain
# to listings inside the bootstrap parser (monchis).
# ---------------------------------------------------------------------------
# pages << {
#   url:       'PLACEHOLDER_AUTH_ENDPOINT',
#   page_type: 'bootstrap',         # parser mints token, sets location, queues listings
#   method:    'POST',
#   headers:   SiteConfig.api_headers,
#   body:      'PLACEHOLDER_AUTH_BODY',
#   vars:      { 'lat' => 'PLACEHOLDER_LAT', 'long' => 'PLACEHOLDER_LONG' }
# }

save_pages(pages) if pages.length > 99
