# ============================================================================
# Helper Functions — greenfield boilerplate
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

def empty_to_nil(str)
  s = str.to_s.strip
  s.empty? || s == '{}' || s == '[]' || s == '.' ? nil : s
end

# ---------------------------------------------------------------------------
# URL helpers
# ---------------------------------------------------------------------------

def fix_image_url(url, base_url: URLs::BASE_URL)
  return nil if url.nil? || url.strip.empty?
  return url if url.start_with?('http')
  "#{base_url}#{url.start_with?('/') ? url : '/' + url}"
end

def encode_url_path(url)
  url.gsub(/[^[:ascii:]]/) { |c|
    c.force_encoding('utf-8').bytes.map { |b| "%%%02X" % b }.join
  }
end

# ---------------------------------------------------------------------------
# Description cleaning
# ---------------------------------------------------------------------------

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

def autorefetch(reason = nil)
  autorecovery(reason: reason)
end

def autolimbo(reason = nil)
  puts "LIMBO: #{reason}" if ENV['debug']
  limbo page['gid']
  finish
end
