# ============================================================================
# Helper Functions — dmart / greenfield boilerplate
# require './lib/helpers'  in every parser
#
# Shared extraction normalizers (json_ld_for_type, og_value, price_from,
# fix_image_url, md5_id, str_empty_to_nil, etc.) live in ./lib/extraction.rb
# ============================================================================

require './lib/extraction'

# Convenience wrappers — thin delegation to Extraction module so parsers
# can call empty_to_nil() without module prefix if preferred.
def empty_to_nil(str)
  Extraction.str_empty_to_nil(str)
end

def text_of(element)
  element&.text&.strip
end

def boolean_from(text)
  text.to_s.downcase.match?(/true|yes|available|in.?stock/i)
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
