# ============================================================================
# Headers and URLs Configuration - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Define HTTP headers and base URL constants used across parsers.
#
# FILES TO UPDATE:
# - URLs::BASE_URL: Update with site's base URL (e.g., "https://example.com")
# - ReqHeaders::MINIMAL_HEADERS: Usually no changes needed (standard headers)
#
# USAGE:
# - Require this file in parsers: require './lib/headers'
# - Access base URL: URLs::BASE_URL
# - Access headers: ReqHeaders::MINIMAL_HEADERS
# ============================================================================

module ReqHeaders
  # Standard HTTP headers for requests
  # Usually no changes needed - these are minimal headers that work for most sites
  MINIMAL_HEADERS = {
    "Accept" => "application/json",
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 OPR/120.0.0.0",
  }
end

module URLs
  # PLACEHOLDER: Update with site's base URL
  # Example: "https://example.com" or "https://www.example.com"
  # Discovery: Extract from site URL during discovery phase
  # Note: Remove trailing slash if present
  BASE_URL = "PLACEHOLDER_BASE_URL"
end