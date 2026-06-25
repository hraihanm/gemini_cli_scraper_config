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

require './lib/headers'

# Error taxonomy: refetch transient 403, limbo persistent 500.
refetch page['gid'] if page['failed_response_status_code'] == 403
if page['failed_response_status_code'] == 500
  limbo page['gid']
  finish
end
if page['response_status_code'] && page['response_status_code'] != 200
  outputs << { _collection: 'listings_fetch_failed', _id: page['url'],
               url: page['url'], status: page['response_status_code'] }
  finish
end

html     = Nokogiri::HTML(content)
base_url = URLs::BASE_URL

# ============================================================================
# PLACEHOLDER: Restaurant Link Selector
# Discovery: Use browser_grep_html(query: "<visible restaurant name>") to find the selector
# Example: ".restaurant-card a", ".venue-item a", "a.restaurant-link"
# ============================================================================
restaurant_links = html.css("PLACEHOLDER_RESTAURANT_LINK_SELECTOR")

restaurant_links.each_with_index do |link, idx|
  begin
    href = link['href']
    next if href.nil? || href.empty?

    restaurant_url = href.start_with?('http') ? href : "#{base_url}#{href}"

    restaurant_name = link.text.strip
    rank = (page['vars']&.dig('page_number').to_i - 1) * 20 + idx + 1 rescue idx + 1

    pages << {
      url:       restaurant_url,
      page_type: "restaurant_details",
      headers:   ReqHeaders::MINIMAL_HEADERS,
      vars: {
        restaurant_name:  restaurant_name,
        rank_in_listing:  rank,
        page_number:      page['vars']&.dig('page_number') || 1,
      }
    }
  rescue => e
    warn "[LISTINGS ERROR] url=#{page['url']} idx=#{idx} error=#{e.message}"
  end
end
warn "[LISTINGS] url=#{page['url']} queued=#{pages.length} restaurants"

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
#   current_page = page['vars']&.dig('page_number')&.to_i || 1
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
#   next_href = next_link['href']
#   next_url  = next_href.start_with?('http') ? next_href : "#{base_url}#{next_href}"
#   pages << {
#     url:       next_url,
#     page_type: "listings",
#     headers:   ReqHeaders::MINIMAL_HEADERS,
#     vars:      { page_number: (page['vars']&.dig('page_number')&.to_i || 1) + 1 }
#   }
# end

save_pages(pages) if pages.length > 99
