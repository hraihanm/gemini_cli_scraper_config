# Finisher Script Template
# Based on DataHen tutorial - generates summaries after all parsing is complete
# Runs after all parsing is complete

# Get collections information from the current job
collections = DataHen::Client::ScraperJobOutput.new.collections(ENV['DH_SCRAPER_NAME'] || 'scraper')

# Process products collection
products_collection = collections.find { |c| c['collection'] == 'products' }
if products_collection
  total_products = products_collection['outputs']
  
  # Generate basic summary
  outputs << {
    _collection: 'summary',
    total_products: total_products,
    collection_name: 'products',
    generated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  }
  
  puts "Generated summary: #{total_products} products found"
else
  puts "No products collection found"
  outputs << {
    _collection: 'summary',
    total_products: 0,
    error: 'No products collection found',
    generated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  }
end

# Process listing metadata if available
listings_collection = collections.find { |c| c['collection'] == 'listing_metadata' }
if listings_collection
  total_listings = listings_collection['outputs']
  
  outputs << {
    _collection: 'summary',
    total_listing_pages: total_listings,
    collection_name: 'listing_metadata',
    generated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  }
  
  puts "Processed #{total_listings} listing pages"
end

# Advanced analysis: Get sample of products for quality analysis
if products_collection && products_collection['outputs'] > 0
  per_page = 100
  last_id = ''
  
  # Counters for data quality metrics
  total_analyzed = 0
  products_with_price = 0
  products_with_image = 0
  products_with_description = 0
  products_with_brand = 0
  products_on_sale = 0
  categories = {}
  brands = {}
  
  while total_analyzed < [products_collection['outputs'], 1000].min  # Limit analysis to 1000 products
    query = {
      '_id' => { '$gt' => last_id },
      '$orderby' => [{ '_id' => 1 }]
    }
    
    products = find_outputs('products', query, 1, per_page)
    break if products.nil? || products.empty?
    
    products.each do |product|
      total_analyzed += 1
      
      # Count data quality metrics
      products_with_price += 1 if product['current_price']
      products_with_image += 1 if product['main_image_url']
      products_with_description += 1 if product['description']
      products_with_brand += 1 if product['brand']
      products_on_sale += 1 if product['has_discount']
      
      # Track categories and brands
      if product['category']
        categories[product['category']] = (categories[product['category']] || 0) + 1
      end
      
      if product['brand']
        brands[product['brand']] = (brands[product['brand']] || 0) + 1
      end
    end
    
    last_id = products.last['_id']
    break if products.length < per_page  # No more products
  end
  
  # Calculate percentages
  price_coverage = total_analyzed > 0 ? (products_with_price.to_f / total_analyzed * 100).round(2) : 0
  image_coverage = total_analyzed > 0 ? (products_with_image.to_f / total_analyzed * 100).round(2) : 0
  description_coverage = total_analyzed > 0 ? (products_with_description.to_f / total_analyzed * 100).round(2) : 0
  brand_coverage = total_analyzed > 0 ? (products_with_brand.to_f / total_analyzed * 100).round(2) : 0
  sale_percentage = total_analyzed > 0 ? (products_on_sale.to_f / total_analyzed * 100).round(2) : 0
  
  # Generate quality report
  outputs << {
    _collection: 'quality_report',
    total_analyzed: total_analyzed,
    data_coverage: {
      price_coverage_percent: price_coverage,
      image_coverage_percent: image_coverage,
      description_coverage_percent: description_coverage,
      brand_coverage_percent: brand_coverage
    },
    business_metrics: {
      products_on_sale: products_on_sale,
      sale_percentage: sale_percentage,
      unique_categories: categories.keys.length,
      unique_brands: brands.keys.length
    },
    top_categories: categories.sort_by { |_, count| -count }.first(10).to_h,
    top_brands: brands.sort_by { |_, count| -count }.first(10).to_h,
    generated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  }
  
  puts "Quality analysis complete:"
  puts "  - Analyzed #{total_analyzed} products"
  puts "  - Price coverage: #{price_coverage}%"
  puts "  - Image coverage: #{image_coverage}%"
  puts "  - Description coverage: #{description_coverage}%"
  puts "  - Brand coverage: #{brand_coverage}%"
  puts "  - Products on sale: #{sale_percentage}%"
end

# Optional: Add custom validation logic here
# You can implement your own quality checks without external dependencies
if products_collection && total_analyzed > 0
  # Simple quality thresholds
  quality_score = 0
  quality_score += 25 if price_coverage > 80
  quality_score += 25 if image_coverage > 70
  quality_score += 25 if description_coverage > 60
  quality_score += 25 if brand_coverage > 50
  
  quality_status = case quality_score
    when 100 then 'excellent'
    when 75..99 then 'good'
    when 50..74 then 'fair'
    else 'poor'
  end
  
  outputs << {
    _collection: 'quality_status',
    quality_score: quality_score,
    quality_status: quality_status,
    meets_threshold: quality_score >= 75,
    generated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
  }
  
  puts "Quality assessment: #{quality_status} (#{quality_score}/100)"
end

# Save all outputs
save_outputs outputs if outputs.length > 0

puts "Finisher completed successfully"
