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
# Error handling — see docs/shared/datahen-autorecovery.md
# ---------------------------------------------------------------------------

MAX_REFETCH = 3

# Standard fetch-error recovery. Route by HTTP status; retry up to MAX_REFETCH times.
# Always calls finish — stops parser execution after recovery action.
def autorecovery(reason: nil, status: nil)
  status ||= page['failed_response_status_code']
  msg = [reason, status && "HTTP #{status}"].compact.join(' | ')
  puts "RECOVERY: #{msg}" if ENV['debug']
  case status
  when 404
    limbo page['gid']
  when 403, 429
    refetch page['gid']
  else
    page['refetch_count'].to_i >= MAX_REFETCH ? limbo(page['gid']) : refetch(page['gid'])
  end
  finish
end

# Backward-compat alias
def autorefetch(reason = nil)
  autorecovery(reason: reason)
end

# Explicit no-retry limbo — for permanent failures or out-of-scope pages
def autolimbo(reason = nil)
  puts "LIMBO: #{reason}" if ENV['debug']
  limbo page['gid']
  finish
end
