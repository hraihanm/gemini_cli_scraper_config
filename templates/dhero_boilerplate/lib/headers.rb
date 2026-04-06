# ============================================================================
# Headers and URLs Configuration - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Define HTTP headers and base URL constants used across parsers.
#
# FILES TO UPDATE:
# - URLs::BASE_URL: Update with site's base URL (e.g., "https://example.com")
# ============================================================================

module ReqHeaders
  MINIMAL_HEADERS = {
    "Accept" => "application/json",
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 OPR/120.0.0.0",
  }
end

module URLs
  # PLACEHOLDER: Update with site's base URL during Phase 1
  BASE_URL = "PLACEHOLDER_BASE_URL"
end
