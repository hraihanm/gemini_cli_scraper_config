# frozen_string_literal: true

# ============================================================================
# Seeder - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Seed the initial restaurant listings page to start the pipeline.
# DHero pipeline: listings → restaurant_details → menu
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: pages
# - DO NOT declare: pages = []
# ============================================================================

require './lib/headers'

pages << {
  # PLACEHOLDER: Update with restaurant listings homepage URL
  url: "PLACEHOLDER_HOMEPAGE_URL",

  # DHero always starts with "listings" (restaurant listing page)
  page_type: "listings",

  method: "GET",
  # PLACEHOLDER: "standard" or "browser" based on discovery
  fetch_type: "PLACEHOLDER_FETCH_TYPE",
  headers: ReqHeaders::MINIMAL_HEADERS,
  priority: 100,

  # PLACEHOLDER: Uncomment if page requires JavaScript/button clicks
  # driver: {
  #   name: "reveal_listings",
  #   code: "await page.click('PLACEHOLDER_BUTTON_SELECTOR'); await sleep(PLACEHOLDER_WAIT_TIME);",
  #   goto_options: { waitUntil: "domcontentloaded" },
  #   stealth: true,
  #   enable_images: false,
  # }
}
