# DataHen Scraper Structure Summary

## Core Components

### 1. Seeder
- Entry point that initializes scraping
- Seeds initial pages into `pages` array 
- Defines starting URLs and page types
- Example structure (minimal configuration):
```ruby
pages << {
  url: "https://site.com/categories",
  page_type: "categories",
  method: "GET", # Default method
  headers: {
    "User-Agent": "???",
  },
  vars: { # Passing information to next page
    category: category,
    category_id: category_id
  }
}
```

### 2. Parsers
- Scripts that extract data from fetched pages after download
- One parser per page type (e.g., "index", "detail")
- Have access to reserved variables:
  - `content`: Raw page HTML/content (String)
  - `page`: Current page metadata (Hash)
  - `page['vars']`: User-defined variables from previous pages (Hash)
  - `pages`: Array to queue new pages
  - `outputs`: Array to store extracted data
  - `save_pages(pages)`: Method to save pages immediately and clear memory
  - `save_outputs(outputs)`: Method to save outputs immediately and clear memory

#### Page Variable Structure
The `page` variable contains comprehensive metadata about the current page:
```ruby
{
  # Page Identification
  "gid": "fetchtest.datahen.com-1767f1fa6b7302b4a618b16b470fc1d2", # Global unique ID
  "job_id": 9793,
  
  # Status Information
  "job_status": "active",
  "status": "parsing_failed",
  
  # Request Configuration
  "fetch_type": "standard",
  "page_type": "qa",
  "priority": 0,
  "method": "GET",
  "url": "https://fetchtest.datahen.com/?scraper=ebay-example",
  "effective_url": "https://fetchtest.datahen.com/?scraper=ebay-example",
  "headers": null,
  "cookie": null,
  "body": null,
  
  # Timing Information
  "created_at": "2019-08-09T21:44:18.709737Z",
  "parsing_at": null,
  "parsing_failed_at": "2019-08-09T22:05:30.684121Z",
  "parsed_at": null,
  "fetched_at": "2019-08-09T21:45:10.312099Z",
  
  # Processing Metrics
  "parsing_try_count": 3,
  "parsing_fail_count": 3,
  "fetching_try_count": 1,
  
  # Response Data
  "response_checksum": "9d650deb8d3fd908de452f27e148293d",
  "response_status": "200 OK",
  "response_status_code": 200,
  "response_proto": "HTTP/1.1",
  "content_type": "text/html; charset=utf-8",
  "content_size": 555,
  
  # Configuration Flags
  "no_redirect": false,
  "ua_type": "desktop",
  "force_fetch": false,
  
  # Custom Data
  "vars": {
    "collections": ["listings"],
    "scraper_name": "ebay-example"
  }
}
```

- Standard structure:
```ruby
html = Nokogiri::HTML(content)
vars = page['vars']

# Extract data
data = html.at_css('.selector')&.text

# Queue next pages
pages << {
  url: next_url,
  page_type: "next_page",
  vars: vars.merge({ extracted: data })
}

# Save outputs
outputs << {
  '_collection': 'collection_name',
  'field': data
}

# Memory management for large datasets
save_pages(pages) if pages.count > 99
save_outputs(outputs) if outputs.count > 99
```

### 3. Job Pages Configuration
- Comprehensive page request configuration:
```ruby
pages << {
  # Basic Configuration
  "url": "https://www.datahen.com",
  "page_type": "my_homepage",
  "priority": 0,
  
  # HTTP Request Configuration
  "method": "POST",
  "headers": {"Foo": "Bar"},
  "cookie": "foo=bar",
  "body": "param1=aaa&param2=bbb",
  "no_redirect": false,
  "no_url_encode": false,
  "http2": false,
  
  # Browser Configuration
  "fetch_type": "fullbrowser",
  "ua_type": "desktop",
  "freshness": "2020-02-12T10:00:00Z",
  
  # Browser Automation
  "driver": {
    "name": "my_code",
    "code": "await page.click('footer li > a'); await sleep(2000);",
    "goto_options": {
      "timeout": 30000,
      "waitUntil": "load"
    }
  },
  
  # Display Settings
  "display": {
    "width": 1920,
    "height": 1080
  },
  
  # Screenshot Configuration
  "screenshot": {
    "take_screenshot": true,
    "options": {
      "fullPage": true,
      "type": "jpeg",
      "quality": 75
    }
  },
  
  # Custom Variables passed from previous page
  "vars": {
    "my_var_a": "abc",
    "my_var_b": 123
  }
}
```

### 4. Finisher
- Post-processing after job completion
- Common uses:
  - Generate summaries
  - Run QA checks
  - Validate scraped data

### 5. Exporters 
- Export data to various formats
- Supported formats:
  - JSON
  - CSV
- Configuration example:
```yaml
exporter_name: products_json
exporter_type: json
collection: products
write_mode: pretty_array
start_on_job_done: true
```

## Key Concepts

### Page Flow
1. Seeder initiates with start URLs
2. Parsers extract data and queue new pages
3. Variables pass between pages via `vars`
4. Outputs save to collections
5. Finisher processes after completion
6. Exporters generate output files

### Data Collections
- Storage containers for scraped data
- Each output requires `_collection` field
- Metadata fields start with `_`
- Support multiple collections per scraper

### Error Handling
- Use conditional checks (`&.`)
- Handle missing elements gracefully
- Always include rescue clauses
- Validate data before saving

### Page Freshness and Force Fetch
- `forceFetch`: Forces re-fetch of non-fresh pages
- Freshness types: day, week, month, year, any
- Only affects existing pages in DataHen platform
- New pages are always fetched regardless of forceFetch

## Configuration (config.yaml)
```yaml
seeder:
  file: ./seeder/seeder.rb
  
parsers:
  - page_type: listings
    file: ./parsers/listings.rb
  - page_type: details 
    file: ./parsers/details.rb
    
exporters:
  - file: ./exporters/data.yaml
    
finisher:
  file: ./finisher/finisher.rb
```

This comprehensive guide covers the essential components and concepts for building DataHen scrapers, including detailed configuration options, memory management, and best practices for handling different types of pages and data extraction scenarios.