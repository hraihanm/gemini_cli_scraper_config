# ============================================================================
# Helper Functions — dmart / greenfield boilerplate
# require './lib/helpers'  in every parser
# ============================================================================

# ---------------------------------------------------------------------------
# Text / type coercion
# ---------------------------------------------------------------------------

def text_of(element)
  element&.text&.strip
end

def number_from(text)
  return nil if text.nil?
  cleaned = text.to_s.gsub(/[^\d.]/, '')
  cleaned.empty? ? nil : cleaned.to_f
end

def boolean_from(text)
  text.to_s.downcase.match?(/true|yes|available|in.?stock/i)
end

# Convert nil/empty/sentinel strings to nil
def empty_to_nil(str)
  s = str.to_s.strip
  s.empty? || s == '{}' || s == '[]' || s == '.' ? nil : s
end

# ---------------------------------------------------------------------------
# URL helpers
# ---------------------------------------------------------------------------

# Normalize relative image URLs to absolute. Replace BASE_URL with the site root.
def fix_image_url(url, base_url: URLs::BASE_URL)
  return nil if url.nil? || url.strip.empty?
  return url if url.start_with?('http')
  "#{base_url}#{url.start_with?('/') ? url : '/' + url}"
end

# Percent-encode non-ASCII characters in a URL path (e.g. Spanish category names)
def encode_url_path(url)
  url.gsub(/[^[:ascii:]]/) { |c|
    c.force_encoding('utf-8').bytes.map { |b| "%%%02X" % b }.join
  }
end

# ---------------------------------------------------------------------------
# Description cleaning
# ---------------------------------------------------------------------------

# Strip HTML tags from a description field while preserving structure.
# Converts headings, list items, and <br> to plain text with newlines.
def clean_html_description(html_str)
  return nil if html_str.nil?
  text = html_str
    .gsub('&nbsp;', ' ').gsub('&ndash;', '-').gsub('&amp;', '&')
    .gsub(/<h[1-6][^>]*>(.*?)<\/h[1-6]>/m) { "\n#{$1.strip}\n" }
    .gsub(/<li[^>]*>(.*?)<\/li>/m)          { "• #{$1.strip}\n" }
    .gsub(/<br\s*\/?>/i, "\n")
    .gsub(/<[^>]+>/, '')
    .gsub(/\n{3,}/, "\n\n")
    .strip
  text.empty? ? nil : text
end

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------

# Standard autorefetch helper — call at top of every parser after status check.
# Retries up to 3 times before sending to limbo for manual review.
def autorefetch(reason)
  puts "AUTO-REFETCH: #{reason}" if ENV['debug']
  if page['refetch_count'].to_i > 3
    limbo page['gid']
  else
    refetch page['gid']
  end
  finish
end
