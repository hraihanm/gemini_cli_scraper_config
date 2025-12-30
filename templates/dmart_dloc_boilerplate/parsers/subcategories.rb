# frozen_string_literal: true

# ============================================================================
# Subcategories Parser - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Extract subcategory links from category pages and queue
#          listing pages for processing.
#
# DATAHEN v3 STRUCTURE:
# - This is a TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined variables available: content, page, pages, outputs
# - DO NOT declare: pages = [], outputs = [], page = {}, content = ""
# - DO NOT wrap in functions - DataHen executes this file directly as a script
#
# VARIABLE FLOW:
# - Receives: category_name, breadcrumb, category_level (from categories parser)
# - Passes to next stage: subcategory_name, category_name, breadcrumb, page_number
#
# PLACEHOLDER REPLACEMENT:
# - Replace 'PLACEHOLDER' strings with discovered CSS selectors from browser tools
# - Test selectors on multiple category pages to ensure reliability
# ============================================================================

require './lib/headers'

# ============================================================================
# Initialize - Access pre-defined DataHen variables
# ============================================================================
# NOTE: content, page, pages, outputs are pre-defined by DataHen
# DO NOT declare them - use directly
html = Nokogiri::HTML(content)
vars = page['vars'] || {}

# Get base URL from lib/headers.rb (update URLs::BASE_URL in lib/headers.rb)
base_url = URLs::BASE_URL

# ============================================================================
# Extract Subcategory Links
# ============================================================================
# PLACEHOLDER: Replace with discovered subcategory link selector
# Example: html.css('.subcategory-item a') or html.css('ul.subcategories li a')
# Discovery: Use browser_inspect_element() to find real CSS selector
# Note: Some sites may not have subcategories - this parser may be disabled in config.yaml
subcategories = html.css('PLACEHOLDER')

subcategories.each do |subcat|
  # Extract subcategory name and URL
  subcat_name = subcat.text.strip
  subcat_url = subcat['href']
  subcat_url = URI.join(base_url, subcat_url).to_s unless subcat_url.start_with?('http')
  
  # Skip if subcategory name or URL is missing
  next if subcat_name.nil? || subcat_url.nil? || subcat_url.empty?

  # ============================================================================
  # Queue Next Page for Processing
  # ============================================================================
  # NOTE: pages is pre-defined by DataHen - DO NOT declare (pages = [] is FORBIDDEN)
  # Use pages << directly to queue pages for DataHen to process
  pages << {
    url: subcat_url,
    page_type: "listings", # Subcategories typically lead to listings pages
    priority: 100,
    headers: ReqHeaders::MINIMAL_HEADERS,
    vars: vars.merge({
      # Navigation context passed to listings parser
      subcategory_name: subcat_name,
      category_name: vars['category_name'], # Preserve parent category name
      breadcrumb: "#{vars['breadcrumb']} > #{subcat_name}",
      page_number: 1 # Start from page 1 for new listings
    })
  }
  
  # Memory management: Save pages to server when array gets large
  # NOTE: save_pages is a pre-defined function - DO NOT declare it
  save_pages if pages.count > 99
end