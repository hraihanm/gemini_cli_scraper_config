# frozen_string_literal: true

# ============================================================================
# Categories Parser - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Extract category links from homepage/categories page and queue
#          subcategory or listing pages for processing.
#
# DATAHEN v3 STRUCTURE:
# - This is a TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined variables available: content, page, pages, outputs
# - DO NOT declare: pages = [], outputs = [], page = {}, content = ""
# - DO NOT wrap in functions - DataHen executes this file directly as a script
#
# VARIABLE FLOW:
# - Receives: base_url (from seeder or vars)
# - Passes to next stage: category_name, category_id, breadcrumb, category_level, page_number
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
# Extract Category Links
# ============================================================================
# PLACEHOLDER: Replace with discovered category link selector
# Example: html.css('.category-item a') or html.css('.nav-menu a.category-link')
# Discovery: Use browser_inspect_element() to find real CSS selector
categories = html.css('PLACEHOLDER')

categories.each do |category|
  # PLACEHOLDER: Replace with discovered category name selector
  # Example: category.at_css('h5.category-title') or category.at_css('.category-name')
  # Discovery: Use browser_inspect_element() to find where category name is located
  cat_name = category.at_css('PLACEHOLDER')&.text&.strip
  
  # Extract category URL from link href attribute
  cat_url = category['href']
  cat_url = URI.join(base_url, cat_url).to_s unless cat_url.start_with?('http')
  
  # Extract category_id (if available)
  # PLACEHOLDER: Replace with discovered category_id extraction method
  # Common sources:
  # - data-category-id attribute: category['data-category-id']
  # - data-id attribute: category['data-id']
  # - From URL: cat_url.match(/category[\/-](\d+)/)[1]
  # - From nested element: category.at_css('[data-category-id]')['data-category-id']
  # Discovery: Use browser_inspect_element() to find where category_id is stored
  category_id = nil
  
  # Try common data attribute patterns
  category_id ||= category['data-category-id'] || category['data-categoryid'] || category['data-id']
  
  # Try nested element with data attribute
  category_id ||= category.at_css('[data-category-id]')&.[]('data-category-id')
  category_id ||= category.at_css('[data-categoryid]')&.[]('data-categoryid')
  
  # Try extracting from URL pattern (if category_id in URL)
  # PLACEHOLDER: Update regex pattern based on site's URL structure
  # Example: /category\/(\d+)/ or /categories\/(\d+)/ or /cat-(\d+)/
  if category_id.nil? && cat_url
    url_match = cat_url.match(/PLACEHOLDER_CATEGORY_ID_REGEX/)
    category_id = url_match[1] if url_match
  end
  
  
  # Skip if category name or URL is missing
  next if cat_name.nil? || cat_url.nil? || cat_url.empty?
  
  # ============================================================================
  # Determine Next Page Type
  # ============================================================================
  # SITE-SPECIFIC LOGIC: Update this based on your site's structure
  # - If categories lead directly to listings: page_type = "listings"
  # - If categories have subcategories: page_type = "subcategories"
  # - If categories lead to category pages: page_type = "categories"
  #
  # Example patterns:
  # - URL contains '/catalogo/' → likely listings page
  # - URL contains '/category/' → likely subcategories page
  # - Check site structure during discovery phase
  page_type_for_next = cat_url.include?('/catalogo/') ? "listings" : "subcategories"
  
  # ============================================================================
  # Queue Next Page for Processing
  # ============================================================================
  # NOTE: pages is pre-defined by DataHen - DO NOT declare (pages = [] is FORBIDDEN)
  # Use pages << directly to queue pages for DataHen to process
  
  # PLACEHOLDER: Configure fetch_type based on site requirements
  # - "standard": Use for static HTML pages (default, faster)
  # - "browser": Use if subcategories/listings require JavaScript or button clicks
  # Discovery: Check if next page type requires browser fetch during navigation discovery
  next_page_config = {
    url: cat_url,
    page_type: page_type_for_next,
    priority: 100,
    headers: ReqHeaders::MINIMAL_HEADERS,
    # PLACEHOLDER: Set fetch_type based on discovery
    # If next page requires button clicks or JavaScript, set to "browser"
    fetch_type: "PLACEHOLDER_FETCH_TYPE", # "standard" or "browser"
    vars: vars.merge({
      # Navigation context passed to next parser
      category_name: cat_name,
      category_id: category_id, # Pass category_id if discovered
      category_level: (vars['category_level'] || 0).to_i + 1,
      breadcrumb: vars['breadcrumb'] ? "#{vars['breadcrumb']} > #{cat_name}" : cat_name,
      page_number: 1
    })
  }
  
  # PLACEHOLDER: Add driver block ONLY if fetch_type is "browser" and button clicks are needed
  # Uncomment and configure if next page requires button clicks to reveal content
  # Common scenarios:
  # - Subcategories hidden behind "Show More" button
  # - Listings require menu interaction to appear
  # If fetch_type is "standard", leave this commented out
  # if next_page_config[:fetch_type] == "browser"
  #   next_page_config[:driver] = {
  #     name: "reveal_content",
  #     # PLACEHOLDER: Replace with discovered button selector
  #     # Example: "await page.click('button.show-more'); await sleep(2000);"
  #     code: "await page.click('PLACEHOLDER_BUTTON_SELECTOR'); await sleep(PLACEHOLDER_WAIT_TIME);",
  #     goto_options: {
  #       waitUntil: "domcontentloaded"
  #     },
  #     stealth: true,
  #     enable_images: false,
  #     disable_adblocker: false
  #   }
  # end
  
  pages << next_page_config
  
  # Memory management: Save pages to server when array gets large
  # NOTE: save_pages(pages) is a pre-defined function - DO NOT declare it
  save_pages(pages) if pages.count > 99
end
