# Simple Finisher Script Template
# Based on DataHen eBay tutorial (Exercise 6) - core pattern only
# Generates basic summary without external dependencies

# Get collections information from the current job
collections = DataHen::Client::ScraperJobOutput.new.collections(ENV['DH_SCRAPER_NAME'] || 'scraper')

# Find the products collection and generate summary
collection = collections.find { |collection| collection['collection'] == "products" }
if collection
  total = collection["outputs"]
  outputs << {
    "_collection" => "summary",
    "total_products" => total
  }
  puts "Generated summary: #{total} products found"
else
  puts "No products collection found"
end

# Find the listings collection if it exists
listings_collection = collections.find { |collection| collection['collection'] == "listings" }
if listings_collection
  total_listings = listings_collection["outputs"]
  outputs << {
    "_collection" => "summary", 
    "total_listing_pages" => total_listings
  }
  puts "Processed #{total_listings} listing pages"
end

# Save outputs
save_outputs outputs if outputs.length > 0

puts "Finisher completed successfully"
