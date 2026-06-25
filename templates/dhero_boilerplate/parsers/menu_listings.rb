# frozen_string_literal: true

# ============================================================================
# Menu Listings Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Discover menu category/page URLs for a restaurant and queue them
#          as page_type: 'menu' pages for the Menu Details parser (Phase 5).
#
# This is a NAVIGATION parser for menus — it mirrors what listings.rb does
# for restaurant discovery. It does NOT extract item data.
#
# STRATEGIES (agent selects the correct one during Phase 4):
#   A — Multi-category / tabbed menu: each category tab becomes one 'menu' page
#   B — Single-page menu: all items on this page — queue current URL directly
#   C — Paginated menu: discover total pages, queue each as 'menu'
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
loc_id          = page['vars']&.dig('loc_id')
restaurant_name = page['vars']&.dig('restaurant_name')
restaurant_url  = page['vars']&.dig('restaurant_url')
cuisine         = page['vars']&.dig('cuisine')

base_vars = {
  loc_id:          loc_id,
  restaurant_name: restaurant_name,
  restaurant_url:  restaurant_url,
  cuisine:         cuisine,
}

queued = 0

# ============================================================================
# Strategy A: Multi-category / tabbed menu
# PLACEHOLDER: Replace with discovered category tab/link selectors.
# Agent discovers these with browser_grep_html during Phase 4.
# ============================================================================
# html.css('PLACEHOLDER_CATEGORY_TAB_SELECTOR').each do |tab|
#   category_name = tab.text.strip
#   next if category_name.empty?
#
#   href = tab['href'] || tab.at_css('a')&.[]('href')
#   next unless href
#
#   category_url = href.start_with?('http') ? href : Addressable::URI.join(page['url'], href).to_s
#
#   pages << {
#     url:       category_url,
#     page_type: 'menu',
#     headers:   ReqHeaders::MINIMAL_HEADERS,
#     vars:      base_vars.merge(category_name: category_name),
#   }
#   queued += 1
# end

# ============================================================================
# Strategy C: Paginated menu (count-based or next-button)
# PLACEHOLDER: Uncomment and adapt for paginated structures.
# ============================================================================
# total_text = html.at_css('PLACEHOLDER_TOTAL_ITEMS_SELECTOR')&.text
# if total_text
#   total_items = total_text.match(/(\d[\d,]*)/)[1].gsub(',', '').to_i
#   items_per_page = 20  # PLACEHOLDER
#   total_pages = (total_items.to_f / items_per_page).ceil
#   (1..total_pages).each do |page_num|
#     pages << {
#       url:       "#{page['url']}?page=#{page_num}",
#       page_type: 'menu',
#       headers:   ReqHeaders::MINIMAL_HEADERS,
#       vars:      base_vars.merge(category_name: nil, page_number: page_num),
#     }
#     queued += 1
#   end
# end

# ============================================================================
# Strategy B: Single-page menu — all items on this page (fallback)
# Used when no separate category/page URLs are found.
#
# 🚨 GID COLLISION: DataHen GID = hash(url). Re-queuing page['url'] with a
# different page_type is silently dropped and the 'menu' page is NEVER fetched
# (see docs/shared/datahen-conventions.md → "Page GID and URL Deduplication").
#
# PREFERRED for a truly single-page menu: extract items inline in
# restaurant_details.rb (Strategy E in docs/workflows/phases/03-restaurant-details.md)
# and disable menu_listings + menu in config.yaml — do NOT route through here.
#
# If you must queue from here, force a distinct GID with a harmless query param.
# Confirm the site ignores the extra param before relying on it.
# ============================================================================
if queued == 0
  sep = page['url'].include?('?') ? '&' : '?'
  pages << {
    url:       "#{page['url']}#{sep}_dh_menu=1",
    page_type: 'menu',
    headers:   ReqHeaders::MINIMAL_HEADERS,
    vars:      base_vars.merge(category_name: nil),
  }
  queued = 1
  warn "[MENU_LISTINGS] single-page fallback used a _dh_menu=1 GID-buster — prefer inline Strategy E"
end

warn "[MENU_LISTINGS] url=#{page['url']} queued=#{queued} menu page(s)"
