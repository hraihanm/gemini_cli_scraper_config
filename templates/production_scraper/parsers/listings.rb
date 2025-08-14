require './lib/autorefetch.rb'
require "./lib/headers"

autorefetch("Blank failed pages") if page['response_status_code'].nil? && page['failed_response_status_code'].nil?

html = Nokogiri::HTML(content)
vars = page['vars']

# Count products on current page - CUSTOMIZE SELECTOR
products_on_page = html.css('PRODUCT_ITEM_SELECTOR_PLACEHOLDER').count

# Extract product URLs - CUSTOMIZE SELECTOR
html.css('PRODUCT_ITEM_SELECTOR_PLACEHOLDER').each_with_index do |prod, idx|
  prod_url = prod.css('a').attr('href')&.text rescue nil
  next if prod_url.nil?

  # Skip invalid URLs
  next if prod_url.include?('%')

  # Handle relative URLs
  if prod_url.start_with?('/')
    base_url = URI.parse(page['url']).tap { |u| u.path = ''; u.query = nil }.to_s
    prod_url = base_url.chomp('/') + prod_url
  end

  pages << {
    url: prod_url,
    method: "GET",
    page_type: 'details',
    headers: page['headers'],
    fetch_type: 'browser',
    vars: {
      rank: idx + 1
    }.merge(vars)
  }
end

# Pagination logic - CUSTOMIZE BASED ON SITE
PRODUCTS_PER_PAGE = 15  # Adjust based on site
current_page = vars['page'] || 1

if current_page == 1 && products_on_page == PRODUCTS_PER_PAGE
  # Extract total products count - CUSTOMIZE SELECTOR
  total_product_text = html.at_css('TOTAL_PRODUCTS_SELECTOR_PLACEHOLDER')&.text
  total_product = total_product_text&.match(/\d+/)&.[](0)&.to_i || 0
  
  if total_product > PRODUCTS_PER_PAGE
    max_pages = (total_product.to_f / PRODUCTS_PER_PAGE).ceil
    
    (2..max_pages).each do |pn|
      paginated_url = page['url'].gsub(/[?&]page=\d+/, '')
      separator = paginated_url.include?('?') ? '&' : '?'
      
      pages << {
        url: "#{paginated_url}#{separator}page=#{pn}",
        method: 'GET',
        fetch_type: 'browser',
        page_type: 'listings',
        priority: 500,
        headers: ReqHeaders::DEFAULT_HEADER,
        vars: vars.merge({ "page" => pn })
      }
    end
  end
end

save_pages pages if pages.length > 99
