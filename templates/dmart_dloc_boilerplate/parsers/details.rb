# frozen_string_literal: true

# ============================================================================
# Details Parser - DataHen v3 Boilerplate
# ============================================================================
#
# PURPOSE: Extract product data from detail pages and output to products collection.
#          This is the final stage of the scraping pipeline.
#
# DATAHEN v3 STRUCTURE:
# - This is a TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined variables available: content, page, pages, outputs
# - DO NOT declare: pages = [], outputs = [], page = {}, content = ""
# - DO NOT wrap in functions - DataHen executes this file directly as a script
#
# VARIABLE FLOW:
# - Receives: category_name, breadcrumb, rank, page_number (from listings parser)
# - Outputs: Complete product data to products collection
#
# PLACEHOLDER REPLACEMENT:
# - Replace ALL 'PLACEHOLDER' strings with discovered CSS selectors from browser tools
# - Test selectors on multiple product pages to ensure reliability
# - Ensure output hash matches config.yaml exporter fields exactly
#
# OUTPUT HASH REQUIREMENTS:
# - Must match config.yaml exporter fields exactly (see config.yaml exporters section)
# - All fields in exporter must be present in output hash
# - Use same field names as in config.yaml
# ============================================================================

require './lib/helpers'
require './lib/regex'
require 'digest'

# ============================================================================
# Initialize - Access pre-defined DataHen variables
# ============================================================================
# NOTE: content, page, pages, outputs are pre-defined by DataHen
# DO NOT declare them - use directly
html = Nokogiri::HTML(content)
vars = page['vars'] || {}

# ============================================================================
# Extract Product Fields from HTML
# ============================================================================
# All PLACEHOLDER strings must be replaced with discovered selectors
# Use browser_inspect_element() and browser_verify_selector() to discover selectors

# ----------------------------------------------------------------------------
# Product Name (REQUIRED)
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered product name selector
# Example: html.at_css('h1.product-title') or html.at_css('.product-name')
# Discovery: Use browser_verify_selector() for text fields
name = html.at_css('PLACEHOLDER')&.text&.strip
raise 'name is nil' if name.nil?

# ----------------------------------------------------------------------------
# SKU, Barcode, and Product ID
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered SKU selector
# Example: html.at_css('[data-sku]') or html.at_css('.sku')
# Discovery: Use browser_inspect_element() to find SKU location
sku_element = html.at_css('PLACEHOLDER')
sku = text_of(sku_element)

# PLACEHOLDER: Replace with discovered product ID selector
# Example: html.at_css('[data-product-id]')&.[]('data-product-id') or html.at_css('#product-id')
# Discovery: Use browser_evaluate() for data attributes
# Note: Prefer data-product-id attribute, fallback to SKU, then generate hash
competitor_product_id_element = html.at_css('PLACEHOLDER')
competitor_product_id = competitor_product_id_element&.[]('data-product-id') ||
                         competitor_product_id_element&.text&.strip ||
                         sku ||
                         Digest::MD5.hexdigest("#{name}#{page['url']}")

# PLACEHOLDER: Replace with discovered barcode selector
# Example: html.at_css('[data-barcode]')&.[]('data-barcode') or html.at_css('.barcode')
# Discovery: Use browser_inspect_element() to find barcode location
barcode_element = html.at_css('PLACEHOLDER')
barcode = barcode_element&.[]('data-barcode') || barcode_element&.text&.strip

# Item identifiers (JSON format for barcode)
item_identifiers = nil
if barcode && !barcode.empty?
  item_identifiers = {barcode: "'#{barcode}'"}.to_json
end

# ----------------------------------------------------------------------------
# Availability Status
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered availability selector
# Example: html.at_css('.availability')&.text&.strip or html.at_css('[data-in-stock]')
# Discovery: Use browser_verify_selector() for text fields
# Note: Convert text to boolean using boolean_from() helper or custom logic
availability_element = html.at_css('PLACEHOLDER')
availability_text = text_of(availability_element)
is_available = boolean_from(availability_text) if availability_text

# ----------------------------------------------------------------------------
# Brand Extraction
# ----------------------------------------------------------------------------
# SITE-SPECIFIC: Update breadcrumb selector based on site structure
# PLACEHOLDER: Replace with discovered breadcrumb selector
# Example: html.css('nav.breadcrumb a') or html.css('.breadcrumbs a')
# Discovery: Use browser_inspect_element() to find breadcrumb navigation
breadcrumb_links = html.css('PLACEHOLDER') # Update selector for your site

brand = nil
if breadcrumb_links.length >= 2
  # Brand is typically the second-to-last link (before the product name link)
  brand_link = breadcrumb_links[-2]
  brand = text_of(brand_link) if brand_link
end

# ----------------------------------------------------------------------------
# Category Extraction from Breadcrumb
# ----------------------------------------------------------------------------
# SITE-SPECIFIC: Update regex pattern based on site's URL structure
# PLACEHOLDER: Update regex pattern to match your site's category URL format
# Example: /catalogo\/(.+)-c(\d+)/ or /category\/(\d+)\/(.+)/
category = nil
categories = []
category_ids = []
sub_categories = nil

breadcrumb_links.each do |link|
  link_text = text_of(link)
  href = link['href'] || ''
  # PLACEHOLDER: Update regex to match your site's category URL pattern
  if href.match(/PLACEHOLDER_REGEX_PATTERN/)
    categories << link_text
    category_ids << $2 # Adjust capture group based on regex
  end
end

category = categories[0]
category_id = category_ids[0]
sub_categories = categories[1..-1]
sub_category = sub_categories.join(' > ') if !sub_categories.empty?

# ----------------------------------------------------------------------------
# Price Extraction
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered customer price selector
# Example: html.at_css('.price') or html.at_css('.current-price')
# Discovery: Use browser_verify_selector() for price text
customer_price_text = html.at_css('PLACEHOLDER')&.text&.strip
customer_price_lc = number_from(customer_price_text) if customer_price_text

# PLACEHOLDER: Replace with discovered base/original price selector
# Example: html.at_css('.original-price') or html.at_css('.was-price')
# Discovery: Use browser_verify_selector() for price text
# Note: Base price may not exist if product has no discount
base_price_text_element = html.at_css('PLACEHOLDER')
base_price_text = text_of(base_price_text_element)
base_price_lc = base_price_text ? number_from(base_price_text) : customer_price_lc

# Price validation and discount calculation
# If base price is missing or invalid, use customer price
base_price_lc = customer_price_lc if base_price_lc.nil? || base_price_lc == 0
base_price_lc = customer_price_lc if base_price_lc < customer_price_lc
has_discount = base_price_lc != customer_price_lc && base_price_lc > 0

# Discount percentage calculation
discount_percentage = has_discount ? ((1.0 - (customer_price_lc / base_price_lc)) * 100).round(7) : nil

# ----------------------------------------------------------------------------
# Description
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered description selector
# Example: html.at_css('.product-description') or html.at_css('#description')
# Discovery: Use browser_verify_selector() for text fields
description_element = html.at_css('PLACEHOLDER')
description = nil
if description_element
  description_text = description_element.text.gsub("\u00A0", "")&.strip
  description = description_text if description_text && !description_text.empty?
end

# ----------------------------------------------------------------------------
# Image URLs
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered primary image selector
# Example: html.at_css('.product-image img')&.[]('src') or html.at_css('#main-image')&.[]('data-src')
# Discovery: Use browser_evaluate() for image src attributes (NOT browser_verify_selector)
img_url = html.at_css('PLACEHOLDER')&.[]('src') ||
          html.at_css('PLACEHOLDER')&.[]('data-src')

# PLACEHOLDER: Replace with discovered secondary image selector (if exists)
# Example: html.css('.product-gallery img') or html.css('.thumbnail img')
# Discovery: Use browser_evaluate() for image src attributes
img_url_2 = html.at_css('PLACEHOLDER')&.[]('src') # if exists, add 3, 4, etc.

# Additional images collection
additional_images = []
# PLACEHOLDER: Replace with discovered additional images selector
# Example: html.css('.product-gallery img') or html.css('.thumbnail img')
html.css('PLACEHOLDER').each_with_index do |img_link, idx|
  next if idx == 0 # Skip first image (already in img_url)
  img_href = img_link['href'] || img_link['data-src'] || img_link['src']
  additional_images << img_href if img_href
end

# ----------------------------------------------------------------------------
# Navigation Context (from vars passed by listings parser)
# ----------------------------------------------------------------------------
rank_in_listing = vars['rank'] || vars['listing_position']
page_number = vars['page_number'] || vars['page']

# ----------------------------------------------------------------------------
# Processed Fields
# ----------------------------------------------------------------------------
is_promoted = has_discount

# Private label detection (SITE-SPECIFIC: Update brand patterns)
# PLACEHOLDER: Update regex pattern to match your site's private label brands
# Example: for Fairprice site, there are private label brands like "Fairprice" and "Fairprice Select"
is_private_label = true
if brand
  is_private_label = !brand.match(/PLACEHOLDER_PRIVATE_LABEL_PATTERN/i)
end
if is_private_label
  is_private_label = false if name.include?(/PLACEHOLDER_PRIVATE_LABEL_PATTERN/i)
end
is_private_label = true if brand.nil? || brand.empty?

# Promo details
promo_detail = []

# PLACEHOLDER: Replace with discovered sale badge selector
# Example: html.at_css('.badge-sale') or html.at_css('.discount-badge')
# Discovery: Use browser_verify_selector() for text fields
onsale_badge = html.at_css('PLACEHOLDER')
onsale_text = text_of(onsale_badge)

if onsale_text && !onsale_text.empty?
  promo_detail << onsale_text
end

promo_attributes = nil
type_of_promotion = nil
if !promo_detail.empty?
  promo_attributes = {promo_detail: "#{promo_detail.map{|t| "'#{t}'"}.join(', ')}"}.to_json
  type_of_promotion = "Badge" # Update based on site's promotion types
end

# ----------------------------------------------------------------------------
# Size Extraction using Helper Module
# ----------------------------------------------------------------------------
# Uses MeasurementExtractor.extract_uom() from lib/regex.rb
# No changes needed - helper handles common measurement patterns
size_std = nil
size_unit_std = nil

uom = MeasurementExtractor.extract_uom(name)
if uom && uom[:size] && uom[:unit]
  size_std = uom[:size].to_f
  size_unit_std = uom[:unit].downcase
end

# ----------------------------------------------------------------------------
# Product Pieces using Helper Module
# ----------------------------------------------------------------------------
# Uses MeasurementExtractor.extract_pieces() from lib/regex.rb
# No changes needed - helper handles common piece patterns
product_pieces = MeasurementExtractor.extract_pieces(name) if name
product_pieces = 1 if product_pieces.nil? || product_pieces == 0

# ----------------------------------------------------------------------------
# Item Attributes
# ----------------------------------------------------------------------------
# SITE-SPECIFIC: Update selector for add-to-cart button or product attributes container
# PLACEHOLDER: Replace with discovered add-to-cart button or attributes container selector
# Example: html.at_css('button.add-to-cart') or html.at_css('[data-product-attributes]')
# Discovery: Use browser_inspect_element() to find attributes location
item_attributes = nil
attributes = []
add_to_cart_button = html.at_css('PLACEHOLDER') # Update selector

if add_to_cart_button
  add_to_cart_button.attributes.each do |attr_name, attr_value|
    if attr_name.start_with?('data-') && attr_name != 'data-product_ean' && attr_name != 'data-product_price'
      attr_key = attr_name.gsub('data-', '').gsub('_', ' ').split.map(&:capitalize).join(' ')
      attributes << attr_key
      attributes << attr_value.value
    end
  end
  item_attributes = attributes.to_json if !attributes.empty?
end

# ----------------------------------------------------------------------------
# Country of Origin and Variants
# ----------------------------------------------------------------------------
# PLACEHOLDER: Replace with discovered country of origin selector
# Example: html.at_css('.country-of-origin') or html.at_css('[data-origin]')
# Discovery: Use browser_inspect_element() to find location
country_of_origin_element = html.at_css('PLACEHOLDER')
country_of_origin = text_of(country_of_origin_element)

# PLACEHOLDER: Replace with discovered variants selector
# Example: html.at_css('.variants') or html.at_css('[data-variants]')
# Discovery: Use browser_inspect_element() to find variants location
# Note: Variants may be in JSON format in data attributes
variants_element = html.at_css('PLACEHOLDER')
variants = variants_element&.[]('data-variants') || text_of(variants_element)

# ============================================================================
# Build Output Hash
# ============================================================================
# CRITICAL: Output hash MUST match config.yaml exporter fields exactly
# Verify that all fields in config.yaml exporters section are present here
# Field names must match exactly (case-sensitive)
#
# NOTE: outputs is pre-defined by DataHen - DO NOT declare (outputs = [] is FORBIDDEN)
# Use outputs << directly to append product data

output = {
  # Collection and ID (REQUIRED)
  _collection: "products",
  _id: competitor_product_id,

  # Site Information (UPDATE THESE VALUES)
  competitor_name: "PLACEHOLDER_COMPETITOR_NAME", # Update with site name
  competitor_type: "local_store", # "dmart" for DMART or "local_store" for DLOC
  store_name: nil, # Update if site has multiple stores
  store_id: nil, # Update if site has store IDs
  country_iso: "PLACEHOLDER_COUNTRY_CODE", # Two letter ISO code (e.g., "PY", "US")
  language: "PLACEHOLDER_LANGUAGE_CODE", # Three letter code (e.g., "SPA", "ENG")
  currency_code_lc: "PLACEHOLDER_CURRENCY_CODE", # Three letter code (e.g., "PYG", "USD")
  scraped_at_timestamp: Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S'),

  # Product Identification
  competitor_product_id: competitor_product_id,
  name: name,
  brand: brand,

  # Category Information
  category_id: category_id,
  category: category,
  sub_category: sub_category,

  # Pricing Information
  customer_price_lc: customer_price_lc.to_s, # Convert to string for CSV export
  base_price_lc: base_price_lc.to_s, # Convert to string for CSV export
  has_discount: has_discount,
  discount_percentage: discount_percentage,

  # Product Details
  rank_in_listing: rank_in_listing,
  product_pieces: product_pieces,
  size_std: size_std,
  size_unit_std: size_unit_std,
  description: description,
  img_url: img_url,
  barcode: barcode,
  sku: sku,
  url: page['url'],
  is_available: is_available,

  # Metadata
  crawled_source: "WEB",
  is_promoted: is_promoted,
  type_of_promotion: type_of_promotion,
  promo_attributes: promo_attributes,
  is_private_label: is_private_label,
  latitude: nil, # Update if site provides location data
  longitude: nil, # Update if site provides location data
  reviews: nil, # Update if extracting reviews
  store_reviews: nil, # Update if extracting store reviews
  item_attributes: item_attributes,
  item_identifiers: item_identifiers,
  page_number: page_number,
  country_of_origin: country_of_origin,
  variants: variants,
}

# Add additional images (img_url_2, img_url_3, etc.)
additional_images.each_with_index do |img_url_additional, index|
  output["img_url_#{index + 2}"] = img_url_additional
end

# Add img_url_2 if discovered separately
output["img_url_2"] = img_url_2 if img_url_2

# ============================================================================
# Output Product Data
# ============================================================================
# NOTE: outputs is pre-defined by DataHen - DO NOT declare (outputs = [] is FORBIDDEN)
# Use outputs << directly to append product data
outputs << output
