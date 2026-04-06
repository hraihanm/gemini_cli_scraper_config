# frozen_string_literal: true

# ============================================================================
# Listings Parser - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Parse restaurant listing pages.
# Queues individual restaurant detail pages for the restaurant_details parser.
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: content, page, pages, outputs
# - DO NOT redeclare any of these variables
# ============================================================================

require 'nokogiri'
require 'addressable'
require './lib/headers'

html     = Nokogiri::HTML(content)
base_url = URLs::BASE_URL

# ============================================================================
# PLACEHOLDER: Restaurant Link Selector
# Discovery: Use browser_grep_html(query: "<visible restaurant name>") to find the selector
# Example: ".restaurant-card a", ".venue-item a", "a.restaurant-link"
# ============================================================================
restaurant_links = html.css("PLACEHOLDER_RESTAURANT_LINK_SELECTOR")

restaurant_links.each_with_index do |link, idx|
  href = link['href']
  next if href.nil? || href.empty?

  # Build absolute URL
  restaurant_url = if href.start_with?('http')
    href
  else
    Addressable::URI.join(base_url, href).to_s
  end

  # Extract restaurant name from link text (or nearby element)
  # PLACEHOLDER: Update selector if name is in a child element
  restaurant_name = link.text.strip

  rank = (page[:vars]&.dig('page_number').to_i - 1) * 20 + idx + 1 rescue idx + 1

  pages << {
    url:       restaurant_url,
    page_type: "restaurant_details",
    headers:   ReqHeaders::MINIMAL_HEADERS,
    vars: {
      restaurant_name:  restaurant_name,
      rank_in_listing:  rank,
      page_number:      page[:vars]&.dig('page_number') || 1,
    }
  }
end

# ============================================================================
# Pagination
# PLACEHOLDER: Update with discovered pagination strategy
# Strategy 1 (count-based) is preferred — update selectors below
# ============================================================================

# Strategy 1: Count-based (RECOMMENDED)
# total_count_text = html.at_css("PLACEHOLDER_COUNT_SELECTOR")&.text
# if total_count_text
#   total = total_count_text.match(/(\d[\d,]*)/)[1].gsub(',','').to_i rescue 0
#   per_page = restaurant_links.length
#   total_pages = (total.to_f / per_page).ceil
#   current_page = page[:vars]&.dig('page_number')&.to_i || 1
#   ((current_page + 1)..total_pages).each do |pnum|
#     pages << {
#       url: "#{base_url}PLACEHOLDER_PAGINATION_PATTERN#{pnum}",
#       page_type: "listings",
#       headers: ReqHeaders::MINIMAL_HEADERS,
#       vars: { page_number: pnum }
#     }
#   end
# end

# Strategy 2: Next button (fallback)
# next_link = html.at_css("PLACEHOLDER_NEXT_BUTTON_SELECTOR")
# if next_link && next_link['href']
#   pages << {
#     url: Addressable::URI.join(base_url, next_link['href']).to_s,
#     page_type: "listings",
#     headers: ReqHeaders::MINIMAL_HEADERS,
#     vars: { page_number: (page[:vars]&.dig('page_number')&.to_i || 1) + 1 }
#   }
# end

save_pages(pages) if pages.length > 99
