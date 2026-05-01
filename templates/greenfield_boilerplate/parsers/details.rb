# frozen_string_literal: true

# Greenfield placeholder — Phase 3 replaces with real extraction from field-spec.json.
# DataHen v3: top-level script; do not wrap in def; pages/outputs/page/content are predefined.

require 'digest'
require './lib/headers'

html = Nokogiri::HTML(content) rescue nil
vars = page['vars'] || {}

fetched_at = page['fetched_at'] || page['fetching_at']
scrape_date = if fetched_at
                Time.parse(fetched_at).utc.iso8601
              else
                Time.now.utc.iso8601
              end

outputs << {
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
save_outputs outputs if outputs.length > 99
