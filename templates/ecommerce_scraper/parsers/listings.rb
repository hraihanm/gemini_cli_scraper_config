# Listings Parser Template
# Extracts product URLs from category/listing pages
# Based on DataHen tutorial patterns

html = Nokogiri::HTML(content)
vars = page['vars'] || {}

# Extract product links from the listing page
# Update selectors based on your target site's structure
product_links = html.css('.product-item a') # Update this selector

product_links.each_with_index do |link, index|
  product_url = link['href']
  
  # Handle relative URLs
  if product_url.start_with?('/')
    base_url = URI.parse(page['url']).tap { |u| u.path = ''; u.query = nil }.to_s
    product_url = base_url + product_url
  end
  
  # Queue product detail pages
  pages << {
    page_type: 'details',
    method: "GET", 
    url: product_url,
    headers: page['headers'],
    priority: 50,  # Lower priority than listing pages
    vars: vars.merge({
      rank: index + 1,
      listing_url: page['url']
    })
  }
end

# Handle pagination
current_page = vars['page'] || 1
max_pages = 10  # Set reasonable limit to prevent infinite loops

# Look for pagination indicators
next_page_link = html.at_css('.pagination .next, .next-page') # Update selector
total_pages_element = html.at_css('.pagination-info') # Update selector

if next_page_link && current_page < max_pages
  next_page_url = next_page_link['href']
  
  # Handle relative URLs for pagination
  if next_page_url.start_with?('/')
    base_url = URI.parse(page['url']).tap { |u| u.path = ''; u.query = nil }.to_s
    next_page_url = base_url + next_page_url
  end
  
  pages << {
    page_type: 'listings',
    method: "GET",
    url: next_page_url,
    headers: page['headers'],
    priority: 75,  # Medium priority for pagination
    vars: vars.merge({
      page: current_page + 1
    })
  }
end

# Alternative pagination: construct URLs programmatically
# Uncomment if the site uses predictable pagination URLs
# if current_page == 1 && current_page < max_pages
#   (2..max_pages).each do |page_num|
#     paginated_url = page['url'].gsub(/(\?|&)page=\d+/, "").chomp('?').chomp('&')
#     separator = paginated_url.include?('?') ? '&' : '?'
#     
#     pages << {
#       page_type: 'listings',
#       method: "GET",
#       url: "#{paginated_url}#{separator}page=#{page_num}",
#       headers: page['headers'],
#       priority: 75,
#       vars: vars.merge({ page: page_num })
#     }
#   end
# end

# Save pages periodically for memory management
save_pages pages if pages.length > 99

# Optional: Extract some listing-level data if needed
# This is useful for category information or listing metadata
listing_info = {
  _collection: 'listing_metadata',
  _id: Digest::MD5.hexdigest(page['url']),
  url: page['url'],
  category: vars['category'],
  page_number: current_page,
  product_count: product_links.length,
  scraped_at: Time.parse(page['fetched_at']).strftime('%Y-%m-%d %H:%M:%S')
}

outputs << listing_info
save_outputs outputs if outputs.length > 99
