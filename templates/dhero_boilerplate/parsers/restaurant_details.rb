# frozen_string_literal: true

# ============================================================================
# Restaurant Details Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Parse individual restaurant pages.
# Extracts restaurant metadata (→ locations collection) and queues the menu
# page for Phase 4.
#
# FIELD SPEC: dhero-field-spec.json — collection: "locations"
# EXTRACTION ORDER: JSON-LD → meta tags → CSS selectors
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: content, page, pages, outputs
# - DO NOT redeclare any of these variables
# ============================================================================

require './lib/headers'
require './lib/extraction'

# ============================================================================
# Error taxonomy (see docs/shared/agent-rules-gemini.md → "Error Taxonomy")
#   Transient (403/timeout/popup) → refetch once, then treat as structural
#   Structural (persistent fail)  → limbo for later diagnosis
# Emit a debug record instead of silently dropping the page.
# ============================================================================
refetch page['gid'] if page['failed_response_status_code'] == 403

if page['failed_response_status_code'] == 500
  limbo page['gid']
  finish
end

if page['response_status_code'] == 404
  outputs << { _collection: 'restaurant_not_found', _id: page['url'], url: page['url'] }
  finish
end

if page['response_status_code'] != 200
  outputs << { _collection: 'restaurant_fetch_failed', _id: page['url'],
               url: page['url'], status: page['response_status_code'] }
  finish
end

html     = Nokogiri::HTML(content)
base_url = URLs::BASE_URL

# ============================================================================
# JSON-LD Pre-check (Priority 1)
# ============================================================================
json_ld = html.css('script[type="application/ld+json"]').lazy.map { |s|
  begin
    parsed = JSON.parse(s.text)
    if parsed.is_a?(Hash) && parsed['@graph'].is_a?(Array)
      parsed['@graph'].find { |i| ['Restaurant', 'LocalBusiness', 'FoodEstablishment'].include?(i['@type']) }
    elsif ['Restaurant', 'LocalBusiness', 'FoodEstablishment'].include?(parsed['@type'])
      parsed
    end
  rescue JSON::ParserError
    nil
  end
}.find(&:itself)

# ============================================================================
# FIND fields — JSON-LD → meta → CSS
# Replace PLACEHOLDER selectors with discovered selectors from browser tools.
# ============================================================================

# restaurant_name
restaurant_name = json_ld&.dig('name')&.strip
restaurant_name ||= html.at_css('meta[property="og:title"]')&.[]('content')&.strip
restaurant_name ||= html.at_css('PLACEHOLDER_NAME_SELECTOR')&.text&.strip

# restaurant_address / restaurant_city / restaurant_area / restaurant_post_code
address_obj      = json_ld&.dig('address')
restaurant_address = address_obj.is_a?(Hash) ? address_obj['streetAddress']&.strip : nil
restaurant_address ||= html.at_css('PLACEHOLDER_ADDRESS_SELECTOR')&.text&.strip

restaurant_city  = address_obj&.dig('addressLocality')&.strip
restaurant_city  ||= html.at_css('PLACEHOLDER_CITY_SELECTOR')&.text&.strip

restaurant_area  = address_obj&.dig('addressRegion')&.strip
restaurant_area  ||= html.at_css('PLACEHOLDER_AREA_SELECTOR')&.text&.strip

restaurant_post_code = address_obj&.dig('postalCode')&.strip
restaurant_post_code ||= html.at_css('PLACEHOLDER_POSTCODE_SELECTOR')&.text&.strip

# restaurant_lat / restaurant_long
geo              = json_ld&.dig('geo')
restaurant_lat   = geo&.dig('latitude')&.to_f
restaurant_lat   = nil if restaurant_lat.to_f == 0
restaurant_lat   ||= html.at_css('meta[property="place:location:latitude"]')&.[]('content')&.to_f

restaurant_long  = geo&.dig('longitude')&.to_f
restaurant_long  = nil if restaurant_long.to_f == 0
restaurant_long  ||= html.at_css('meta[property="place:location:longitude"]')&.[]('content')&.to_f

# phone_number
phone_number  = json_ld&.dig('telephone')&.strip
phone_number  ||= html.at_css('meta[property="business:contact_data:phone_number"]')&.[]('content')
phone_number  ||= html.at_css('PLACEHOLDER_PHONE_SELECTOR')&.text&.strip
phone_number  = nil if phone_number&.empty?

# main_cuisine / cuisine_name
cuisine_raw   = json_ld&.dig('servesCuisine')
main_cuisine  = cuisine_raw.is_a?(Array) ? cuisine_raw.first&.strip : cuisine_raw&.strip
main_cuisine  ||= html.at_css('PLACEHOLDER_CUISINE_SELECTOR')&.text&.strip

cuisines_list = cuisine_raw.is_a?(Array) ? cuisine_raw : [cuisine_raw].compact
if cuisines_list.empty?
  cuisines_list = html.css('PLACEHOLDER_CUISINES_SELECTOR').map { |el| el.text.strip }.reject(&:empty?)
end
cuisine_name = Extraction.cuisine_hash(cuisines_list)   # → {cuisine1:..} or nil

# restaurant_rating / number_of_ratings
rating_obj        = json_ld&.dig('aggregateRating')
restaurant_rating = rating_obj&.dig('ratingValue')&.to_f
restaurant_rating = nil if restaurant_rating.to_f == 0
restaurant_rating ||= html.at_css('PLACEHOLDER_RATING_SELECTOR')&.text&.strip&.to_f

number_of_ratings = rating_obj&.dig('reviewCount')&.to_i
number_of_ratings = nil if number_of_ratings.to_i == 0
number_of_ratings ||= html.at_css('PLACEHOLDER_RATING_COUNT_SELECTOR')&.text&.gsub(/[^\d]/, '')&.to_i

# opening_hours — {Mon: ["HHMM-HHMM"], ...}
# PLACEHOLDER: Parse raw_hours into the day-keyed hash format.
# JSON-LD may provide openingHours (string array) or openingHoursSpecification (object array).
opening_hours = nil
# raw_hours = json_ld&.dig('openingHours') || json_ld&.dig('openingHoursSpecification')
# opening_hours = parse_opening_hours(raw_hours) if raw_hours

# restaurant_tags — array of feature strings
restaurant_tags = html.css('PLACEHOLDER_TAGS_SELECTOR').map { |t| t.text.strip }.reject(&:empty?)
restaurant_tags = nil if restaurant_tags.empty?

# restaurant_delivers — DETERMINE from tags or delivery badge
restaurant_delivers = restaurant_tags&.include?('PLACEHOLDER_DELIVERY_TAG') ||
                      !html.at_css('PLACEHOLDER_DELIVERS_SELECTOR').nil?

# restaurant_delivery_zones — array of {delivery_zone, minimum_order_value, delivery_fee, currency}
# PLACEHOLDER: Parse delivery zone data from page if available.
restaurant_delivery_zones = nil

# is_permanently_closed — always false for available restaurants
# Client only wants open restaurants. If the site has a closed-indicator selector,
# use it to skip permanently closed restaurants during the listings phase instead.
# Set to null only when confirmed during feasibility that no suitable selector exists.
is_permanently_closed = false

# input_lat / input_long — from the seed/input list (geo seeding only).
# Always emitted (nil-safe) so the output stays spec-complete; populated only
# when the seeder passes input_lat/input_long vars (geo_grid / h3 strategies).
input_lat  = page['vars']&.dig('input_lat')&.to_f
input_long = page['vars']&.dig('input_long')&.to_f
# PLACEHOLDER (optional): synthesize a single delivery zone when the source lacks one:
# restaurant_delivery_zones = [{
#   delivery_zone:        restaurant_city,
#   minimum_order_value:  nil,
#   delivery_fee:         nil,
#   currency:             'PLACEHOLDER_CURRENCY',
# }]

# img_url
img_url  = json_ld&.dig('image').then { |i| i.is_a?(Array) ? i.first : i }
img_url  ||= html.at_css('meta[property="og:image"]')&.[]('content')
img_url  ||= html.at_css('PLACEHOLDER_IMG_SELECTOR')&.[]('src')

# description
description  = json_ld&.dig('description')&.strip
description  ||= html.at_css('meta[property="og:description"]')&.[]('content')&.strip
description  ||= html.at_css('PLACEHOLDER_DESCRIPTION_SELECTOR')&.text&.strip
description  = nil if description&.empty?

# ============================================================================
# DETERMINE — lead_id
# ============================================================================
# Required field guard — never emit a location without a name (would break A1).
if Extraction.str_empty_to_nil(restaurant_name).nil?
  outputs << { _collection: 'restaurant_not_parsable', _id: page['url'], url: page['url'] }
  finish
end

lead_id = Extraction.md5_id(restaurant_name, restaurant_city, restaurant_address)

# ============================================================================
# Output — locations collection
# ============================================================================
begin
  output = {
    _collection: 'locations',
    _id:         lead_id,

    # --- HARDCODED ---
    date:            Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
    url:             page['url'],
    crawled_source:  'WEB',

    # --- INFER (set during Phase 1 site discovery) ---
    restaurant_country: 'PLACEHOLDER_COUNTRY_ISO',  # e.g. 'AE', 'PA', 'BD'

    # --- FROM_VARS ---
    restaurant_position: page['vars']&.dig('rank_in_listing'),

    # --- FIND / DETERMINE ---
    lead_id:                   lead_id,
    restaurant_name:           restaurant_name,
    restaurant_address:        restaurant_address,
    restaurant_city:           restaurant_city,
    restaurant_area:           restaurant_area,
    restaurant_post_code:      restaurant_post_code,
    restaurant_lat:            restaurant_lat,
    restaurant_long:           restaurant_long,
    phone_number:              phone_number,
    main_cuisine:              main_cuisine,
    restaurant_rating:         restaurant_rating,
    number_of_ratings:         number_of_ratings,
    restaurant_delivers:       restaurant_delivers,
    is_permanently_closed:     is_permanently_closed,
    input_lat:                 input_lat,   # nil unless geo-seeded
    input_long:                input_long,  # nil unless geo-seeded

    # --- A2 fields (also present in A1: opening_hours, restaurant_tags, restaurant_delivery_zones) ---
    opening_hours:             opening_hours,
    restaurant_tags:           restaurant_tags,
    restaurant_delivery_zones: restaurant_delivery_zones,
    cuisine_name:              cuisine_name,
    free_field:                nil,

    # --- internal ---
    img_url:                   img_url,
    description:               description,
  }

  nil_fields = output.reject { |k, _| %i[_collection _id crawled_source free_field].include?(k) }
                     .select { |_, v| v.nil? }.keys
  warn "[DETAILS] url=#{page['url']} nil=#{nil_fields.count}/#{output.length} fields: #{nil_fields.join(', ')}" unless nil_fields.empty?

  outputs << output
rescue => e
  warn "[DETAILS ERROR] url=#{page['url']} error=#{e.message} (#{e.class})"
end

# ============================================================================
# Queue Menu Listings Page (Phase 4)
# Passes the restaurant's menu root URL to the menu_listings parser.
# menu_listings will discover category/page URLs and queue 'menu' pages.
#
# Option A: separate /menu sub-URL (strip .html, append /menu) — check first
# Option B: inline on same page — reuse current URL
# Option C: explicit link on the page — use discovered href
# Agent selects the correct option during Phase 3 discovery.
# ============================================================================
menu_root_url = page['url'].sub(/\.html$/, '') + '/menu'
# Option B (inline): menu_root_url = page['url']
# Option C (link):   menu_href = html.at_css('PLACEHOLDER_MENU_LINK_SELECTOR')&.[]('href')
#                    menu_root_url = menu_href ? Addressable::URI.join(page['url'], menu_href).to_s : page['url']

pages << {
  url:       menu_root_url,
  page_type: 'menu_listings',
  headers:   ReqHeaders::MINIMAL_HEADERS,
  vars: {
    loc_id:          lead_id,
    restaurant_name: restaurant_name,
    restaurant_url:  page['url'],
    cuisine:         main_cuisine,
  }
}

save_outputs(outputs) if outputs.length > 99
save_pages(pages)     if pages.length > 99
