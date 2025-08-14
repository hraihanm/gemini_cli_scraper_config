# E-commerce Seeder Template
# Based on DataHen eBay scraper tutorial
# Seeds category/listing pages to begin the scraping process

# Define custom headers if needed
headers = {
  'User-Agent' => 'Mozilla/5.0 (compatible; DataHen Scraper)',
  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
}

# Seed main category/listing pages
# Replace with your target URLs and appropriate page_types
pages << {
  page_type: 'listings',
  method: "GET",
  url: "https://example-store.com/category/electronics",
  headers: headers,
  priority: 100,  # Higher priority for initial pages
  vars: {
    category: 'electronics',
    page: 1
  }
}

# You can seed multiple categories at once
categories = [
  { name: 'electronics', url: 'https://example-store.com/category/electronics' },
  { name: 'clothing', url: 'https://example-store.com/category/clothing' },
  { name: 'home-garden', url: 'https://example-store.com/category/home-garden' }
]

categories.each do |category|
  pages << {
    page_type: 'listings',
    method: "GET",
    url: category[:url],
    headers: headers,
    priority: 100,
    vars: {
      category: category[:name],
      page: 1
    }
  }
end

# Save pages if you have many to avoid memory issues
save_pages pages if pages.length > 99
