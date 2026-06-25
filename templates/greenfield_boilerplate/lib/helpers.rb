# ============================================================================
# Helper Functions — greenfield boilerplate
# require './lib/helpers'  in every parser
#
# Shared extraction normalizers live in ./lib/extraction.rb
# ============================================================================

require './lib/extraction'

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
