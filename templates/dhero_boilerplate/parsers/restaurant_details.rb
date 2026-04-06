# frozen_string_literal: true

# ============================================================================
# Restaurant Details Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Parse individual restaurant pages.
# Extracts restaurant metadata AND queues the menu page for Phase 4.
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: content, page, pages, outputs
# - DO NOT redeclare any of these variables
# ============================================================================

require 'nokogiri'
require 'addressable'
require 'json'
require './lib/headers'

html     = Nokogiri::HTML(content)
base_url = URLs::BASE_URL

# ============================================================================
# JSON-LD Pre-check (Priority 1)
# Many restaurant sites use schema.org Restaurant or LocalBusiness
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
# Field Extraction
# PLACEHOLDER: Replace CSS selectors with discovered selectors
# Priority: JSON-LD → Meta tags → CSS selectors
# ============================================================================

# Restaurant name
name = json_ld&.dig('name')&.strip
name ||= html.at_css('meta[property="og:title"]')&.[]('content')&.strip
name ||= html.at_css("PLACEHOLDER_NAME_SELECTOR")&.text&.strip

# Cuisine type
cuisine = json_ld&.dig('servesCuisine')
cuisine ||= html.at_css("PLACEHOLDER_CUISINE_SELECTOR")&.text&.strip

# Address
address_obj = json_ld&.dig('address')
address = if address_obj.is_a?(Hash)
  [address_obj['streetAddress'], address_obj['addressLocality'], address_obj['addressRegion']].compact.join(', ')
else
  html.at_css("PLACEHOLDER_ADDRESS_SELECTOR")&.text&.strip
end

# Phone
phone = json_ld&.dig('telephone')
phone ||= html.at_css("PLACEHOLDER_PHONE_SELECTOR")&.text&.strip

# Rating
rating_obj  = json_ld&.dig('aggregateRating')
rating      = rating_obj&.dig('ratingValue')&.to_f
rating_count = rating_obj&.dig('reviewCount')&.to_i
rating      ||= html.at_css("PLACEHOLDER_RATING_SELECTOR")&.text&.strip&.to_f
rating_count ||= html.at_css("PLACEHOLDER_RATING_COUNT_SELECTOR")&.text&.strip&.gsub(/[^\d]/, '')&.to_i

# Opening hours
opening_hours = json_ld&.dig('openingHours')
opening_hours ||= html.at_css("PLACEHOLDER_HOURS_SELECTOR")&.text&.strip

# Image
img_url = json_ld&.dig('image').then { |i| i.is_a?(Array) ? i[0] : i }
img_url ||= html.at_css('meta[property="og:image"]')&.[]('content')
img_url ||= html.at_css("PLACEHOLDER_IMG_SELECTOR")&.[]('src')

# Description
description = json_ld&.dig('description')&.strip
description ||= html.at_css('meta[property="og:description"]')&.[]('content')&.strip
description ||= html.at_css("PLACEHOLDER_DESCRIPTION_SELECTOR")&.text&.strip

# Operational status
is_open_now = html.at_css("PLACEHOLDER_OPEN_STATUS_SELECTOR")&.text&.downcase&.include?('open')

# Delivery info (if food delivery platform)
delivery_time = html.at_css("PLACEHOLDER_DELIVERY_TIME_SELECTOR")&.text&.strip
min_order     = html.at_css("PLACEHOLDER_MIN_ORDER_SELECTOR")&.text&.strip&.gsub(/[^\d.]/, '')&.to_f

# Tags (dietary labels, features)
tag_elements = html.css("PLACEHOLDER_TAGS_SELECTOR")
tags = tag_elements.map { |t| t.text.strip }.reject(&:empty?).join(', ')
tags = nil if tags.empty?

# ============================================================================
# Output: Restaurant metadata
# ============================================================================
warn "WARN: name is nil for #{page[:url]}"    if name.nil?
warn "WARN: cuisine is nil for #{page[:url]}" if cuisine.nil?

outputs << {
  name:                  name,
  cuisine:               cuisine,
  address:               address,
  phone:                 phone,
  rating:                rating,
  rating_count:          rating_count,
  opening_hours:         opening_hours,
  img_url:               img_url,
  description:           description,
  is_open_now:           is_open_now,
  delivery_time:         delivery_time,
  min_order:             min_order,
  tags:                  tags,
  rank_in_listing:       page[:vars]&.dig('rank_in_listing'),
  page_number:           page[:vars]&.dig('page_number'),
  url:                   page[:url],
  scraped_at_timestamp:  Time.now.utc.iso8601,
  crawled_source:        'WEB',
}

# ============================================================================
# Queue Menu Page (for Phase 4: Menu Parser)
# PLACEHOLDER: Update menu_url logic based on site structure
# Option A: Menu is on the same page (inline) — reuse current URL
# Option B: Menu is on a separate URL — discover and use that URL
# ============================================================================

# Option A: Menu inline on same page (most common)
menu_url = page[:url]

# Option B: Separate menu URL (uncomment if applicable)
# menu_href = html.at_css("PLACEHOLDER_MENU_LINK_SELECTOR")&.[]('href')
# menu_url = menu_href ? Addressable::URI.join(base_url, menu_href).to_s : page[:url]

pages << {
  url:       menu_url,
  page_type: "menu",
  headers:   ReqHeaders::MINIMAL_HEADERS,
  vars: {
    restaurant_name: name,
    restaurant_url:  page[:url],
    cuisine:         cuisine,
  }
}

save_outputs(outputs) if outputs.length > 99
save_pages(pages)     if pages.length > 99
