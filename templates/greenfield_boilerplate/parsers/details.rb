# frozen_string_literal: true

# Greenfield placeholder — Phase 3 replaces with real extraction from field-spec.json.
# DataHen v3: top-level script; do not wrap in def; pages/outputs/page/content are predefined.

require 'digest'
require './lib/headers'

# Error taxonomy: refetch transient 403, limbo persistent 500, debug-log other non-200.
refetch page['gid'] if page['failed_response_status_code'] == 403
if page['failed_response_status_code'] == 500
  limbo page['gid']
  finish
end
if page['response_status_code'] == 404
  outputs << { _collection: 'product_not_found', _id: page['url'], url: page['url'] }
  finish
end
if page['response_status_code'] && page['response_status_code'] != 200
  outputs << { _collection: 'product_fetch_failed', _id: page['url'],
               url: page['url'], status: page['response_status_code'] }
  finish
end

html = Nokogiri::HTML(content) rescue nil
vars = page['vars'] || {}

fetched_at = page['fetched_at'] || page['fetching_at']
scrape_date = if fetched_at
                Time.parse(fetched_at).utc.iso8601
              else
                Time.now.utc.iso8601
              end

begin
  output = {
    '_collection' => 'products',
    '_id' => Digest::MD5.hexdigest(page['url']).to_s[0, 16],
    'source' => nil,
    'country' => nil,
    'name' => nil,
    'address' => nil,
    'date' => scrape_date,
    'source_url' => page['url'],
    'phone' => nil,
    'website' => nil,
    'cuisine' => nil,
    'price_range' => nil,
    'hours' => nil,
    'lat' => nil,
    'lng' => nil,
    'rating' => nil,
    'rating_count' => nil,
    'registration_number' => nil,
    'licence_expiry' => nil,
    'city' => nil,
    'postal_code' => nil,
  }

  nil_fields = output.select { |_, v| v.nil? }.keys
  warn "[DETAILS] url=#{page['url']} nil=#{nil_fields.count}/#{output.length} fields: #{nil_fields.join(', ')}" unless nil_fields.empty?

  outputs << output
  save_outputs outputs if outputs.length > 99
rescue => e
  warn "[DETAILS ERROR] url=#{page['url']} error=#{e.message} (#{e.class})"
end
