# frozen_string_literal: true

# ============================================================================
# Menu Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Parse restaurant menu pages and extract menu items.
# This is the final phase of the DHero pipeline.
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: content, page, pages, outputs
# - DO NOT redeclare any of these variables
# ============================================================================

require 'nokogiri'
require 'json'
require './lib/headers'

html = Nokogiri::HTML(content)

# Restaurant context (passed from restaurant_details parser via vars)
restaurant_name = page[:vars]&.dig('restaurant_name')
restaurant_url  = page[:vars]&.dig('restaurant_url')
cuisine         = page[:vars]&.dig('cuisine')

# ============================================================================
# Embedded JSON Check (Priority 1 for menu data)
# Many food delivery sites embed menu data as JSON in the page
# ============================================================================

# Check for window.__NEXT_DATA__ or similar embedded JSON (inspect via browser tools)
# PLACEHOLDER: Uncomment and adapt if embedded JSON is found
#
# raw_script = html.css('script#__NEXT_DATA__').first&.text
# if raw_script
#   next_data = JSON.parse(raw_script) rescue nil
#   menu_items = next_data&.dig('props', 'pageProps', 'menu', 'categories') || []
#   menu_items.each do |section|
#     category_name = section['name']
#     (section['items'] || []).each do |item|
#       outputs << {
#         restaurant_name:       restaurant_name,
#         restaurant_url:        restaurant_url,
#         cuisine:               cuisine,
#         category_name:         category_name,
#         name:                  item['name'],
#         description:           item['description'],
#         customer_price_lc:     item['price']&.to_f,
#         currency_code_lc:      'PLACEHOLDER_CURRENCY',
#         img_url:               item['imageUrl'],
#         is_available:          !item['soldOut'],
#         item_attributes:       nil,
#         barcode:               nil,
#         sku:                   item['id']&.to_s,
#         url:                   page[:url],
#         scraped_at_timestamp:  Time.now.utc.iso8601,
#         crawled_source:        'WEB',
#       }
#     end
#   end
# end

# ============================================================================
# CSS Selector Fallback (when no embedded JSON found)
# PLACEHOLDER: Replace selectors with discovered selectors
# ============================================================================

# Iterate menu sections
html.css("PLACEHOLDER_MENU_SECTION_SELECTOR").each do |section|
  # Menu section/category name (e.g., "Starters", "Mains", "Desserts")
  category_name = section.at_css("PLACEHOLDER_SECTION_TITLE_SELECTOR")&.text&.strip

  # Individual menu items within this section
  section.css("PLACEHOLDER_MENU_ITEM_SELECTOR").each_with_index do |item, idx|
    name        = item.at_css("PLACEHOLDER_ITEM_NAME_SELECTOR")&.text&.strip
    next if name.nil? || name.empty?

    description  = item.at_css("PLACEHOLDER_ITEM_DESCRIPTION_SELECTOR")&.text&.strip
    price_text   = item.at_css("PLACEHOLDER_ITEM_PRICE_SELECTOR")&.text&.strip
    customer_price_lc = price_text&.gsub(/[^\d.]/, '')&.to_f

    img_url      = item.at_css("PLACEHOLDER_ITEM_IMG_SELECTOR")&.[]('src')
    img_url    ||= item.at_css("PLACEHOLDER_ITEM_IMG_SELECTOR")&.[]('data-src')

    # Availability: check for sold-out marker
    # PLACEHOLDER: Update sold-out selector
    is_available = item.at_css("PLACEHOLDER_SOLD_OUT_SELECTOR").nil?

    # Item tags (dietary labels, features: vegetarian, spicy, halal, new, etc.)
    # PLACEHOLDER: Update tag selector
    item_tags   = item.css("PLACEHOLDER_ITEM_TAGS_SELECTOR").map { |t| t.text.strip }.reject(&:empty?)
    item_attributes = item_tags.any? ?
      JSON.generate({ 'tags' => item_tags.map { |t| "'#{t}'" }.join(', ') }) : nil

    # Item ID / SKU (if available in data attributes or JSON)
    sku = item['data-item-id'] || item['data-id']

    warn "WARN: customer_price_lc is nil for item '#{name}'" if customer_price_lc.nil? || customer_price_lc == 0

    outputs << {
      restaurant_name:       restaurant_name,
      restaurant_url:        restaurant_url,
      cuisine:               cuisine,
      category_name:         category_name,
      name:                  name,
      description:           description,
      customer_price_lc:     customer_price_lc,
      # PLACEHOLDER: Update with actual currency code discovered during Phase 1
      currency_code_lc:      'PLACEHOLDER_CURRENCY',
      img_url:               img_url,
      is_available:          is_available,
      item_attributes:       item_attributes,
      barcode:               nil,
      sku:                   sku,
      url:                   page[:url],
      scraped_at_timestamp:  Time.now.utc.iso8601,
      crawled_source:        'WEB',
    }
  end
end

save_outputs(outputs) if outputs.length > 99
