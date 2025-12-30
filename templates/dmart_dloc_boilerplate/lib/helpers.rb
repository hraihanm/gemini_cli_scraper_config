# ============================================================================
# Helper Functions - DataHen v3 Boilerplate
# ============================================================================
# 
# PURPOSE: Common utility functions used across parser files for data extraction.
#
# USAGE:
# - Require in parsers: require './lib/helpers'
# - Use directly: text_of(element), number_from(text), boolean_from(text)
#
# NO CHANGES NEEDED:
# - These functions are generic and work for most sites
# - Only modify if site has specific text/number/boolean patterns
# ============================================================================

# Extract text content from an element safely
# Returns nil if element is nil, otherwise returns stripped text
# Usage: text_of(html.at_css('.selector'))
def text_of(element)
  element&.text&.strip
end

# Extract number from text (removes currency symbols, commas, etc.)
# Returns float value or nil if text is nil/empty
# Usage: number_from("$1,234.56") => 1234.56
# Usage: number_from(html.at_css('.price')&.text) => 1234.56
def number_from(text)
  text.to_s.gsub(/[^\d.]/, '').to_f if text
end

# Convert text to boolean based on common availability patterns
# Returns true if text matches "available", "in stock", etc.
# Usage: boolean_from("In Stock") => true
# Usage: boolean_from(html.at_css('.availability')&.text) => true/false
def boolean_from(text)
  text.to_s.downcase.match?(/true|yes|available|in.?stock/i)
end

