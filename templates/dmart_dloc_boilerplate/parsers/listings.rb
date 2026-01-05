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
# - Receives: category_name, category_id, breadcrumb, page_number (from categories/subcategories parser)
# - Passes to next stage: rank, page_number, listing_position, category_name, category_id, breadcrumb
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
      category_id: vars['category_id'], # Preserve category_id from parent category
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
# PRIORITY ORDER (try in this sequence):
# Strategy 1: Count-Based Calculation + Auto-Discovery (TOP PRIORITY - try first)
# Strategy 2: Next Button (fallback if Strategy 1 fails)
# Strategy 3: Infinite Scroll (requires browser automation - document in notes)
# Strategy 4: Query Parameter Pattern (?page=2) (fallback)
# Strategy 5: Path Pattern (/page/2) (fallback)

# ----------------------------------------------------------------------------
# Strategy 1: Count-Based Calculation + Auto-Discovery (TOP PRIORITY)
# ----------------------------------------------------------------------------
# This strategy:
# 1. Discovers product count selector and extracts total count
# 2. Calculates total pages based on products per page
# 3. Auto-discovers pagination pattern (query param, path, or next button)
# 4. Generates all pagination URLs
# Only run on first page to avoid duplicate pagination
if vars['page_number'] == 1 || vars['page'] == 1 || vars['page_number'].nil?
  # Step 1: Discover product count
  # Try common selectors for product count display
  product_count_text = nil
  product_count = nil
  
  # Common product count selectors (try in order)
  count_selectors = [
    'PLACEHOLDER_PRODUCT_COUNT',  # Primary: Replace with discovered selector
    '[class*="count"]',
    '[class*="total"]',
    '[class*="results"]',
    '[class*="product-count"]',
    'p.result-count',
    '.result-count',
    '[id*="count"]',
    '[id*="total"]'
  ]
  
  count_selectors.each do |selector|
    next if selector == 'PLACEHOLDER_PRODUCT_COUNT' && selector.include?('PLACEHOLDER')
    element = html.at_css(selector)
    next unless element
    product_count_text = element.text
    break if product_count_text && !product_count_text.strip.empty?
  end
  
  # Step 2: Extract number from count text using regex patterns
  if product_count_text
    # Try common regex patterns for extracting count
    regex_patterns = [
      /PLACEHOLDER_REGEX/,  # Primary: Replace with discovered regex pattern
      /(\d+)\s*(?:results?|products?|items?)/i,
      /(?:showing|mostrando|mostrar)\s*\d+[–-]\d+\s*(?:of|de)\s*(\d+)/i,
      /(\d+)\s*(?:total|en total)/i,
      /(\d+)/  # Fallback: just get first number
    ]
    
    regex_patterns.each do |pattern|
      next if pattern.to_s.include?('PLACEHOLDER') && pattern.to_s == '/PLACEHOLDER_REGEX/'
      match = product_count_text.match(pattern)
      if match && match[1]
        product_count = match[1].to_i
        break
      end
    end
  end
  
  # Step 3: Calculate total pages if count found
  if product_count && product_count > 0 && products.length > 0
    products_per_page = products.length
    total_pages = (product_count.to_f / products_per_page).ceil
    
    # Step 4: Auto-discover pagination pattern and generate URLs
    if total_pages > 1
      base_url_clean = page['url'].split('?').first  # Remove existing query params
      
      # Try pagination patterns in priority order:
      pagination_patterns = [
        # Pattern 1: Query parameter (?page=2, ?p=2, ?pagina=2)
        ->(num) { "#{base_url_clean}?page=#{num}" },
        ->(num) { "#{base_url_clean}?p=#{num}" },
        ->(num) { "#{base_url_clean}?pagina=#{num}" },
        ->(num) { "#{page['url']}&page=#{num}" },  # Append to existing params
        
        # Pattern 2: Path pattern (/page/2, /pagina/2, /p/2)
        ->(num) { "#{base_url_clean}/page/#{num}" },
        ->(num) { "#{base_url_clean}/pagina/#{num}" },
        ->(num) { "#{base_url_clean}/p/#{num}" },
        ->(num) { base_url_clean.gsub(/\/page\/\d+/, '') + "/page/#{num}" },
        
        # Pattern 3: Next button (if available, use its href pattern)
        # This will be discovered by Strategy 2 if Strategy 1 pattern fails
      ]
      
      # Generate pagination URLs using first pattern (query param is most common)
      # PLACEHOLDER: Replace with discovered pattern if different
      # Example: If site uses ?pagina=2, update the pattern below
      (2..total_pages).each do |page_num|
        # Default to query parameter pattern (most common)
        # PLACEHOLDER: Update if site uses different pattern (discovered via browser tools)
        next_url = "#{base_url_clean}?page=#{page_num}"
        
        # Alternative patterns (uncomment and use if query param doesn't work):
        # next_url = "#{base_url_clean}/page/#{page_num}"  # Path pattern
        # next_url = "#{base_url_clean}?p=#{page_num}"     # Different query param
        
        pages << {
          url: next_url,
          page_type: "listings",
          priority: 50,
          vars: vars.merge({ page_number: page_num })
        }
        save_pages if pages.count > 99
      end
    end
  end
end

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

