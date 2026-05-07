# frozen_string_literal: true

# ============================================================================
# Menu Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Parse restaurant menu pages and extract menu items.
# Final phase of the DHero pipeline.
#
# FIELD SPEC: spec_full.json — collection: "items"
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: content, page, pages, outputs
# - DO NOT redeclare any of these variables
# ============================================================================

require './lib/headers'

html = Nokogiri::HTML(content)

# ============================================================================
# FROM_VARS — context passed from restaurant_details parser
# ============================================================================
restaurant_id   = page['vars']&.dig('loc_id')
restaurant_name = page['vars']&.dig('restaurant_name')
restaurant_url  = page['vars']&.dig('restaurant_url')
cuisine         = page['vars']&.dig('cuisine')

# ============================================================================
# Embedded JSON Check (Priority 1)
# Many food delivery sites embed menu data as JSON — check before CSS fallback.
# PLACEHOLDER: Inspect page source for window.__NEXT_DATA__, __INITIAL_STATE__,
# or similar. Use browser_network_search to find the relevant request/response.
# ============================================================================
# raw_script = html.css('script#__NEXT_DATA__').first&.text
# if raw_script
#   next_data   = JSON.parse(raw_script) rescue nil
#   categories  = next_data&.dig('props', 'pageProps', 'menu', 'categories') || []
#   categories.each do |section|
#     category_name = section['name']
#     (section['items'] || []).each_with_index do |item_data, idx|
#       item_name        = item_data['name']
#       next if item_name.nil? || item_name.empty?
#       item_description = item_data['description']
#       item_price       = item_data['price']&.to_f
#       item_price       = nil if item_price == 0
#       img_url          = item_data['imageUrl']
#       is_available     = !item_data['soldOut']
#       item_is_promoted = false
#       item_id          = Digest::MD5.hexdigest("#{restaurant_id}_#{item_name}_#{idx}")
#
#       outputs << {
#         _collection:     'items',
#         _id:             item_id,
#         date:            Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
#         url:             page['url'],
#         crawled_source:  'WEB',
#         free_field:      nil,
#         currency:        'PLACEHOLDER_CURRENCY',
#         lead_id:         restaurant_id,
#         restaurant_id:   restaurant_id,
#         restaurant_name: restaurant_name,
#         restaurant_url:  restaurant_url,
#         cuisine:         cuisine,
#         item_id:         item_id,
#         category_name:   category_name,
#         item_name:       item_name,
#         item_description: item_description,
#         item_price:      item_price,
#         item_is_promoted: item_is_promoted,
#         img_url:         img_url,
#         is_available:    is_available,
#         item_attributes: nil,
#         barcode:         nil,
#         sku:             item_data['id']&.to_s,
#       }
#     end
#   end
#   save_outputs(outputs) if outputs.length > 99
#   warn "[LISTINGS] url=#{page['url']} queued=#{outputs.length} items"
#   return
# end

# ============================================================================
# CSS Selector Fallback
# Replace PLACEHOLDER selectors with discovered selectors from browser tools.
# ============================================================================
html.css('PLACEHOLDER_MENU_SECTION_SELECTOR').each do |section|
  category_name = section.at_css('PLACEHOLDER_SECTION_TITLE_SELECTOR')&.text&.strip

  section.css('PLACEHOLDER_MENU_ITEM_SELECTOR').each_with_index do |el, idx|
    begin
      item_name = el.at_css('PLACEHOLDER_ITEM_NAME_SELECTOR')&.text&.strip
      next if item_name.nil? || item_name.empty?

      item_description  = el.at_css('PLACEHOLDER_ITEM_DESCRIPTION_SELECTOR')&.text&.strip
      item_description  = nil if item_description&.empty?

      price_text  = el.at_css('PLACEHOLDER_ITEM_PRICE_SELECTOR')&.text&.strip
      item_price  = price_text&.gsub(/[^\d.]/, '')&.to_f
      item_price  = nil if item_price.to_f == 0
      warn "WARN: item_price is nil for '#{item_name}' idx=#{idx}" if item_price.nil?

      img_url  = el.at_css('PLACEHOLDER_ITEM_IMG_SELECTOR')&.[]('src')
      img_url  ||= el.at_css('PLACEHOLDER_ITEM_IMG_SELECTOR')&.[]('data-src')

      is_available = el.at_css('PLACEHOLDER_SOLD_OUT_SELECTOR').nil?

      item_tags       = el.css('PLACEHOLDER_ITEM_TAGS_SELECTOR').map { |t| t.text.strip }.reject(&:empty?)
      item_attributes = item_tags.any? ? JSON.generate({ 'tags' => item_tags.map { |t| "'#{t}'" }.join(', ') }) : nil

      # PLACEHOLDER: Detect promotion via section header name, badge element, or data attribute.
      item_is_promoted = false
      # item_is_promoted = category_name&.downcase == 'promotions'
      # item_is_promoted ||= !el.at_css('PLACEHOLDER_PROMO_BADGE_SELECTOR').nil?

      sku     = el['data-item-id'] || el['data-id']
      item_id = Digest::MD5.hexdigest("#{restaurant_id}_#{item_name}_#{idx}")

      outputs << {
        _collection: 'items',
        _id:         item_id,

        # --- HARDCODED ---
        date:           Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
        url:            page['url'],
        crawled_source: 'WEB',
        free_field:     nil,

        # --- INFER (set during Phase 1) ---
        currency: 'PLACEHOLDER_CURRENCY',  # e.g. 'USD', 'AED', 'BDT'

        # --- FROM_VARS ---
        lead_id:         restaurant_id,
        restaurant_id:   restaurant_id,
        restaurant_name: restaurant_name,
        restaurant_url:  restaurant_url,
        cuisine:         cuisine,

        # --- FIND / DETERMINE ---
        item_id:          item_id,
        category_name:    category_name,
        item_name:        item_name,
        item_description: item_description,
        item_price:       item_price,
        item_is_promoted: item_is_promoted,
        img_url:          img_url,
        is_available:     is_available,
        item_attributes:  item_attributes,
        barcode:          nil,
        sku:              sku,
      }
    rescue => e
      warn "[LISTINGS ERROR] url=#{page['url']} idx=#{idx} error=#{e.message}"
    end
  end
end

warn "[LISTINGS] url=#{page['url']} queued=#{outputs.length} items"

save_outputs(outputs) if outputs.length > 99
