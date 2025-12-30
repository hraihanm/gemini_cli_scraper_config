# frozen_string_literal: true

# ============================================================================
# Seeder - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Seed the initial page(s) to start the scraping pipeline.
#          This is the entry point - DataHen executes this first.
#
# DATAHEN v3 STRUCTURE:
# - This is a TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined variables available: pages
# - DO NOT declare: pages = []
# - DO NOT wrap in functions - DataHen executes this file directly as a script
#
# FILES TO UPDATE:
# - url: Update with site's homepage URL
# - page_type: Update based on site structure ("categories" or "listings")
#   * "categories" if site has category navigation
#   * "listings" if site goes directly to product listings
# ============================================================================

require './lib/headers'

# ============================================================================
# Seed Initial Page
# ============================================================================
# NOTE: pages is pre-defined by DataHen - DO NOT declare (pages = [] is FORBIDDEN)
# Use pages << directly to queue the initial page

pages << {
  # PLACEHOLDER: Update with site's homepage URL
  # Example: "https://example.com" or "https://www.example.com"
  # Discovery: Use site URL from discovery phase
  url: "PLACEHOLDER_HOMEPAGE_URL",
  
  # PLACEHOLDER: Update based on site structure
  # - "categories" if site has category navigation (most common)
  # - "listings" if site goes directly to product listings (rare)
  # Discovery: Determine during site discovery phase
  page_type: "PLACEHOLDER_PAGE_TYPE", # "categories" or "listings"
  
  method: "GET",
  fetch_type: "standard",
  headers: ReqHeaders::MINIMAL_HEADERS, # Using minimal headers by default
  priority: 100, # High priority for initial page
}
