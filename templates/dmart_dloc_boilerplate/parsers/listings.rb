# frozen_string_literal: true

# ============================================================================
# Listings Parser - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Extract product links from listing pages and queue detail pages
#          for processing. Also handles pagination to discover all products.
#
# DATAHEN v3 STRUCTURE:
# - This is a TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined variables available: content, page, pages, outputs
# - DO NOT declare: pages = [], outputs = [], page = {}, content = ""
# - DO NOT wrap in functions - DataHen executes this file directly as a script
#
# VARIABLE FLOW:
# - Receives: category_name, breadcrumb, page_number (from categories/subcategories parser)
# - Passes to next stage: rank, page_number, listing_position, category_name, breadcrumb
#
# PLACEHOLDER REPLACEMENT:
# - Replace 'PLACEHOLDER' strings with discovered CSS selectors from browser tools
# - Test selectors on multiple listing pages to ensure reliability
# ============================================================================

require './lib/headers'
require 'uri'

# ============================================================================
# Initialize - Access pre-defined DataHen variables
# ============================================================================
# NOTE: content, page, pages, outputs are pre-defined by DataHen
# DO NOT declare them - use directly
html = Nokogiri::HTML(content)
vars = page['vars'] || {}

# Get base URL from lib/headers.rb (update URLs::BASE_URL in lib/headers.rb)
base_url = vars['base_url'] || URLs::BASE_URL || page['url'].split('/')[0..2].join('/')

# ============================================================================
# Extract Product Links
# ============================================================================
# PLACEHOLDER: Replace with discovered product link selector
# Example: html.css('.product-item a') or html.css('.product-card a.product-link')
# Discovery: Use browser_inspect_element() to find real CSS selector
# Note: Selector should target the <a> tag or container with href attribute
products = html.css('PLACEHOLDER')

products.each_with_index do |product_link, idx|
  # Extract product URL from link href attribute
  # Handle both direct links and nested links (product_link.at_css('a')['href'])
  product_url = product_link['href'] || product_link.at_css('a')&.[]('href')
  product_url = URI.join(base_url, product_url).to_s unless product_url&.start_with?('http')
  
  # Skip if product URL is missing
  next if product_url.nil? || product_url.empty?
  
  # ============================================================================
  # Queue Detail Page for Processing
  # ============================================================================
  # NOTE: pages is pre-defined by DataHen - DO NOT declare (pages = [] is FORBIDDEN)
  # Use pages << directly to queue pages for DataHen to process
  pages << {
    url: product_url,
    page_type: "details",
    vars: vars.merge({
      # Navigation context passed to details parser
      rank: idx + 1, # Product position in listing (1-based)
      page_number: vars['page_number'] || vars['page'] || 1,
      listing_position: idx + 1, # Position within current page
      # Preserve category context
      category_name: vars['category_name'],
      subcategory_name: vars['subcategory_name'],
      breadcrumb: vars['breadcrumb']
    })
  }
  
  # Memory management: Save pages to server when array gets large
  # NOTE: save_pages is a pre-defined function - DO NOT declare it
  save_pages if pages.count > 99
end

# ============================================================================
# Pagination Handling
# ============================================================================
# IMPORTANT: Choose ONE pagination strategy based on site structure
# Strategy 1: Count-Based Calculation (if product count is displayed)
# Strategy 2: Next Button (most common)
# Strategy 3: Infinite Scroll (requires browser automation - document in notes - need to check network requests)
# Strategy 4: Query Parameter Pattern (?page=2)
# Strategy 5: Path Pattern (/page/2)

# ----------------------------------------------------------------------------
# Strategy 1: Count-Based Calculation (SITE-SPECIFIC - update selectors and regex)
# ----------------------------------------------------------------------------
# Use this if site displays total product count and you can calculate pages
# PLACEHOLDER: Replace with discovered product count selector and regex pattern
# Example: html.at_css('p.result-count') with regex /(\d+) results/
# Only run on first page to avoid duplicate pagination
# Probably the site implements query parameter or path pattern pagination as well
# if vars['page_number'] == 1 || vars['page'] == 1
#   # PLACEHOLDER: Replace with discovered product count selector
#   product_count_text = html.at_css('PLACEHOLDER')&.text
#   # PLACEHOLDER: Update regex pattern to match site's count format
#   # Example: /Mostrando \d+–\d+ de (\d+) resultados/ or /(\d+) products/
#   product_count = product_count_text&.match(/PLACEHOLDER_REGEX/)&.[](1)&.to_i
#   
#   if product_count && product_count > 0
#     products_per_page = products.length
#     total_pages = (product_count.to_f / products_per_page).ceil
#     
#     # Generate pagination URLs for remaining pages
#     (2..total_pages).each do |page_num|
#       # PLACEHOLDER: Update URL pattern based on site's pagination structure
#       # Example: "#{page['url']}?page=#{page_num}" or "#{page['url']}/page/#{page_num}"
#       next_url = "#{page['url']}PLACEHOLDER_PAGINATION_PATTERN"
#       pages << {
#         url: next_url,
#         page_type: "listings",
#         priority: 50,
#         vars: vars.merge({ page_number: page_num })
#       }
#       save_pages if pages.count > 99
#     end
#   end
# end

# ----------------------------------------------------------------------------
# Strategy 2: Next Button Pagination (uncomment and update selector)
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered next button selector
# Example: html.at_css('a.next') or html.at_css('a[aria-label="Next"]')
# Discovery: Use browser_inspect_element() to find real CSS selector
# next_button = html.at_css('PLACEHOLDER')
# if next_button && next_button['href']
#   next_url = next_button['href']
#   next_url = URI.join(base_url, next_url).to_s unless next_url.start_with?('http')
#   
#   pages << {
#     url: next_url,
#     page_type: "listings",
#     vars: vars.merge({ page_number: (vars['page_number'] || 1).to_i + 1 })
#   }
#   save_pages if pages.count > 99
# end

# ----------------------------------------------------------------------------
# Strategy 4: Query Parameter Pattern (uncomment and update pattern)
# ----------------------------------------------------------------------------
# If pagination uses ?page=2, ?page=3 pattern:
# current_page = vars['page_number'] || 1
# next_page = current_page + 1
# next_url = "#{page['url'].split('?').first}?page=#{next_page}"
# pages << {
#   url: next_url,
#   page_type: "listings",
#   vars: vars.merge({ page_number: next_page })
# }
# save_pages if pages.count > 99

# ----------------------------------------------------------------------------
# Strategy 5: Path Pattern (uncomment and update pattern)
# ----------------------------------------------------------------------------
# If pagination uses /page/2, /page/3 pattern:
# current_page = vars['page_number'] || 1
# next_page = current_page + 1
# base_path = page['url'].gsub(/\/page\/\d+/, '')
# next_url = "#{base_path}/page/#{next_page}"
# pages << {
#   url: next_url,
#   page_type: "listings",
#   vars: vars.merge({ page_number: next_page })
# }
# save_pages if pages.count > 99

