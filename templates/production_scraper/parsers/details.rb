require './lib/autorefetch.rb'

autorefetch("Blank failed pages") if page['response_status_code'].nil? && page['failed_response_status_code'].nil?

# Handle unavailable products
if [content, failed_content].any? { |t| t&.include?('UNAVAILABLE_TEXT_PLACEHOLDER') }
  outputs << {
    _collection: "products_no_longer_available",
    url: page['url']
  }
  limbo page['gid']
end

html = Nokogiri::HTML(content) rescue nil
vars = page['vars']

# Basic product extraction - CUSTOMIZE ALL SELECTORS BASED ON CSV SPEC
name = html.at_css('PRODUCT_NAME_SELECTOR_PLACEHOLDER')&.text&.strip
sku = html.at_css('PRODUCT_SKU_SELECTOR_PLACEHOLDER')&.text&.strip
brand = html.at_css('PRODUCT_BRAND_SELECTOR_PLACEHOLDER')&.text&.strip

# Refetch if essential data is missing
if name.nil? || name.empty?
  pages << {
    url: page['url'],
    method: "GET",
    page_type: 'details',
    headers: ReqHeaders::PRODUCT_HEADER,
    driver: { name: "refetch_1" },
    fetch_type: 'browser',
    vars: page['vars']
  }
  finish
end

# Generate SKU if not found
if sku.nil? || sku.empty?
  sku = page['url'].match(/\/product\/([^\/]+)/)[1] rescue Digest::MD5.hexdigest(page['url'])[0..10]
end

# Price extraction - CUSTOMIZE SELECTORS
current_price = nil
original_price = nil

# Regular price
price_element = html.at_css('PRODUCT_PRICE_SELECTOR_PLACEHOLDER')
if price_element
  current_price = price_element.text.strip.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue nil
end

# Discounted price handling
sale_price_element = html.at_css('SALE_PRICE_SELECTOR_PLACEHOLDER')
original_price_element = html.at_css('ORIGINAL_PRICE_SELECTOR_PLACEHOLDER')

if sale_price_element
  current_price = sale_price_element.text.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue current_price
end

if original_price_element
  original_price = original_price_element.text.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue nil
end

# Calculate discount
has_discount = original_price && current_price && original_price > current_price
discount_percentage = has_discount ? ((original_price - current_price) / original_price * 100).round(2) : nil

# Other product details - CUSTOMIZE SELECTORS
img_url = html.at_css('PRODUCT_IMAGE_SELECTOR_PLACEHOLDER')&.[]('src')
description = html.at_css('PRODUCT_DESCRIPTION_SELECTOR_PLACEHOLDER')&.text&.strip
is_available = !html.at_css('OUT_OF_STOCK_SELECTOR_PLACEHOLDER')

# Category extraction
category = html.css('BREADCRUMB_SELECTOR_PLACEHOLDER')[1]&.text&.strip rescue vars['category_name']
sub_category = html.css('BREADCRUMB_SELECTOR_PLACEHOLDER')[2..-1]&.map(&:text)&.map(&:strip)&.join(' > ') rescue nil

# Size and unit extraction using regex patterns
size_std = nil
size_unit_std = nil
regexps = [
  /(\d*[\.,]?\d+)\s?([Ff][Ll]\.?\s?[Oo][Zz])/,
  /(\d*[\.,]?\d+)\s?([Oo][Zz]$)/,
  /(\d*[\.,]?\d+)\s?([Mm][Ll])/,
  /(\d*[\.,]?\d+)\s?([Ll])/,
  /(\d*[\.,]?\d+)\s?([Gg])$/,
  /(\d*[\.,]?\d+)\s?([Kk][Gg])/i,
  /(\d*[\.,]?\d+)\s?([Cc][Mm])/i,
]
regexps.find { |regexp| name =~ regexp }
size_std = $1&.sub(/^\./, '') if $1
size_unit_std = $2 if $2

# Product pieces extraction
product_pieces = nil
piece_regexps = [
  /(\d*[\.,]?\d+)\s?(pcs|pieces)/i,
  /(\d*[\.,]?\d+)\s?(bags?)/i,
  /(\d*[\.,]?\d+)\s?(packs?)/i,
  /(\d*[\.,]?\d+)\s+(x)\s+/i,
]
piece_regexps.find { |regexp| name =~ regexp }
product_pieces = $1&.to_i || 1

# Timestamp handling
fetched_at = page['fetched_at'] || page['fetching_at']

# Build output according to CSV specification
output_hash = {
  '_collection' => 'products',
  '_id' => sku.to_s,
  
  # Standard fields - CUSTOMIZE BASED ON CSV SPEC
  'competitor_name' => 'COMPETITOR_NAME_PLACEHOLDER',
  'competitor_type' => 'COMPETITOR_TYPE_PLACEHOLDER',
  'store_name' => 'STORE_NAME_PLACEHOLDER',
  'store_id' => 1,
  'country_iso' => 'COUNTRY_ISO_PLACEHOLDER',
  'language' => 'LANGUAGE_PLACEHOLDER',
  'currency_code_lc' => 'CURRENCY_CODE_PLACEHOLDER',
  'scraped_at_timestamp' => Time.parse(fetched_at).strftime('%Y-%m-%d %H:%M:%S'),
  
  # Product fields mapped from CSV spec
  'competitor_product_id' => sku,
  'name' => name,
  'brand' => brand,
  'category' => category,
  'sub_category' => sub_category,
  'customer_price_lc' => current_price,
  'base_price_lc' => original_price || current_price,
  'has_discount' => has_discount,
  'discount_percentage' => discount_percentage,
  'description' => description,
  'img_url' => img_url,
  'sku' => sku,
  'url' => page['url'],
  'is_available' => is_available,
  
  # Additional fields
  'rank_in_listing' => vars['rank'],
  'page_number' => vars['page'] || 1,
  'product_pieces' => product_pieces,
  'size_std' => size_std,
  'size_unit_std' => size_unit_std,
  'crawled_source' => 'WEB'
}

# Handle zero price products
if (current_price || 0).to_f == 0.0
  output_hash['_collection'] = 'products_with_zero_price'
end

outputs << output_hash
save_outputs outputs if outputs.length > 99
