# Product Details Parser Template  
# Extracts product information from detail pages
# Based on DataHen tutorial patterns with comprehensive error handling

html = Nokogiri::HTML(content)
vars = page['vars'] || {}

# Basic product information - update selectors for your target site
name = html.at_css('h1.product-title, .product-name h1')&.text&.strip rescue nil
sku = html.at_css('[data-product-id], .product-sku')&.text&.strip rescue nil
brand = html.at_css('.product-brand, .brand-name')&.text&.strip rescue nil

# Handle missing SKU by generating from URL or other identifier
if sku.nil?
  # Extract from URL pattern or use other identifier
  sku = page['url'].match(/\/product\/([^\/]+)/)[1] rescue Digest::MD5.hexdigest(page['url'])[0..10]
end

# Pricing information with error handling
price_element = html.at_css('.price, .product-price .current-price')
current_price = nil
original_price = nil

if price_element
  price_text = price_element.text.strip
  current_price = price_text.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue nil
end

# Check for sale/discount pricing
sale_price_element = html.at_css('.sale-price, .discounted-price')
original_price_element = html.at_css('.original-price, .was-price')

if sale_price_element
  current_price = sale_price_element.text.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue current_price
end

if original_price_element
  original_price = original_price_element.text.gsub(/[^\d\.,]/, '').gsub(',', '').to_f rescue nil
end

# Calculate discount information
has_discount = original_price && current_price && original_price > current_price
discount_percentage = has_discount ? ((original_price - current_price) / original_price * 100).round(2) : nil

# Availability status
availability_element = html.at_css('.availability, .stock-status')
availability_text = availability_element&.text&.strip&.downcase rescue 'unknown'
is_available = !['out of stock', 'unavailable', 'sold out'].any? { |status| availability_text.include?(status) }

# Product images
main_image = html.at_css('.product-image img, .main-product-image')&.[]('src') rescue nil
image_urls = html.css('.product-images img, .product-gallery img').map { |img| img['src'] }.compact rescue []

# Product description
description_element = html.at_css('.product-description, .description, .product-details')
description = description_element&.text&.strip rescue nil

# Category information - use from vars or extract from page
category = vars['category'] rescue nil
breadcrumbs = html.css('.breadcrumb a, .breadcrumbs a').map(&:text).map(&:strip) rescue []
category = breadcrumbs[-2] if category.nil? && breadcrumbs.length > 1

# Product specifications (if available)
specs = {}
html.css('.specifications tr, .product-specs tr').each do |row|
  key_cell = row.at_css('td:first-child, th:first-child')
  value_cell = row.at_css('td:last-child')
  
  if key_cell && value_cell
    key = key_cell.text.strip.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, '_')
    value = value_cell.text.strip
    specs[key] = value unless key.empty? || value.empty?
  end
end rescue nil

# Reviews/ratings if available
rating_element = html.at_css('.rating, .product-rating [data-rating]')
rating = nil
if rating_element
  rating_text = rating_element.text || rating_element['data-rating']
  rating = rating_text.to_f rescue nil
end

review_count_element = html.at_css('.review-count, .reviews-count')
review_count = review_count_element&.text&.gsub(/[^\d]/, '')&.to_i rescue 0

# Extract size/weight information using regex patterns
size_info = {}
size_patterns = [
  /(\d+(?:\.\d+)?)\s*(oz|fl\.?\s?oz|ounces?)/i,
  /(\d+(?:\.\d+)?)\s*(lb|lbs|pounds?)/i,
  /(\d+(?:\.\d+)?)\s*(ml|milliliters?)/i,
  /(\d+(?:\.\d+)?)\s*(l|liter|litres?)/i,
  /(\d+(?:\.\d+)?)\s*(g|grams?)/i,
  /(\d+(?:\.\d+)?)\s*(kg|kilograms?)/i
]

size_patterns.each do |pattern|
  if name&.match(pattern) || description&.match(pattern)
    size_info[:value] = $1.to_f
    size_info[:unit] = $2.downcase
    break
  end
end

# Construct the output hash
output_hash = {
  _collection: 'products',
  _id: sku.to_s,
  
  # Basic information
  name: name,
  brand: brand,
  sku: sku,
  url: page['url'],
  
  # Pricing
  current_price: current_price,
  original_price: original_price,
  has_discount: has_discount,
  discount_percentage: discount_percentage,
  
  # Availability
  is_available: is_available,
  availability_text: availability_text,
  
  # Media
  main_image_url: main_image,
  image_urls: image_urls,
  
  # Content
  description: description,
  category: category,
  breadcrumbs: breadcrumbs,
  
  # Reviews
  rating: rating,
  review_count: review_count,
  
  # Size information
  size_value: size_info[:value],
  size_unit: size_info[:unit],
  
  # Metadata from parsing chain
  rank: vars['rank'],
  listing_url: vars['listing_url'],
  page_number: vars['page'],
  
  # Specifications
  specifications: specs.empty? ? nil : specs,
  
  # Timestamps
  scraped_at: Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S'),
  
  # Data quality indicators
  has_price: !current_price.nil?,
  has_image: !main_image.nil?,
  has_description: !description.nil?
}

# Only save products with essential information
if name && sku
  outputs << output_hash
else
  puts "Skipping product due to missing essential data: name=#{name}, sku=#{sku}, url=#{page['url']}"
end

# Save outputs periodically for memory management
save_outputs outputs if outputs.length > 99
