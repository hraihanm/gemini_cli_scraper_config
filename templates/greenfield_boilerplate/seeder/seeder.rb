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
  # PLACEHOLDER: Update fetch_type based on site requirements
  # - "standard": Use for static HTML pages (default, faster)
  # - "browser": Use if page requires JavaScript execution or button clicks to reveal categories
  # Discovery: Check if categories are visible in DOM without JavaScript
  #   If categories require button clicks or JavaScript to appear, use "browser"
  fetch_type: "PLACEHOLDER_FETCH_TYPE", # "standard" or "browser"
  headers: ReqHeaders::MINIMAL_HEADERS, # Using minimal headers by default
  priority: 100, # High priority for initial page

  # PLACEHOLDER: Uncomment and configure driver block ONLY if fetch_type is "browser"
  # Use this when categories require button clicks or JavaScript to appear in DOM
  # Common scenarios:
  # - Hamburger menu button to reveal navigation
  # - "Show Categories" button
  # - Menu toggle buttons
  # - Any button that reveals category links
  #
  # If fetch_type is "standard", leave this entire driver block commented out
  # driver: {
  #   name: "reveal_categories",
  #   # PLACEHOLDER: Replace with discovered button selector that reveals categories
  #   # Example: "await page.click('button.menu-toggle'); await sleep(2000);"
  #   # Discovery: Use browser_inspect_element() to find button selector
  #   # Common patterns:
  #   # - Hamburger menu: "await page.click('button.hamburger, .menu-toggle'); await sleep(2000);"
  #   # - Show categories: "await page.click('button.show-categories'); await sleep(2000);"
  #   # - Menu button: "await page.click('[aria-label=\"Menu\"]'); await sleep(2000);"
  #   code: "await page.click('PLACEHOLDER_BUTTON_SELECTOR'); await sleep(PLACEHOLDER_WAIT_TIME);",
  #   goto_options: {
  #     waitUntil: "domcontentloaded" # Wait for DOM to be ready
  #   },
  #   stealth: true, # Use stealth mode to avoid detection
  #   enable_images: false, # Disable images for faster loading
  #   disable_adblocker: false # Keep adblocker disabled
  # }
}
