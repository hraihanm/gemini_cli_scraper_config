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

- Comprehensive page fetch configuration:
```ruby
pages << {
  # Basic Configuration
  "url": "https://www.datahen.com",
  "page_type": "my_homepage",
  "priority": 0,
  
  # HTTP Request Configuration
  "method": "POST", # Default is get
  "headers": {"Foo": "Bar"},
  "cookie": "foo=bar",
  "body": "param1=aaa&param2=bbb",

  # Mostly uneeded
  "no_redirect": false,
  "no_url_encode": false,
  "http2": false,
  
  # Browser Configuration
  "fetch_type": "standard", # The default one is standard can also be "browser" if the page enforces javascript
  
  # Browser Automation (most of the time we don't need this)
  "driver": {
    "name": "my_code",
    "code": "await page.click('footer li > a'); await sleep(2000);", # A puppeteer code
    "goto_options": {
      "timeout": 30000,
      "waitUntil": "load"
    }
  },
  
  # Custom Variables passed from previous page
  "vars": {
    "category": "Food Cupboard",
    "category_id": "1234"
  }
}
```

### 2. Parsers
- Scripts that extract data from fetched pages after download
- One parser per page type (e.g., "index", "detail")
- Have access to reserved variables:
  - `content`: Raw page HTML or JSON (String)
  - `page`: Current page metadata (Hash). Usually we write `vars = page['vars']` to access user-defined variables from previous pages (Hash)
  - `pages`: Array to queue new pages. The pages to be enqueued will be fetched later
  - `outputs`: Array to store extracted data, the job output.
  - `save_pages(pages)`: Save an array of pages right away and remove all elements from the array. By default this is not necessary because the seeder will save the "pages" variable. However, if we are seeding large number of pages (thousands), it is better to use this method, to avoid storing everything in memory
  - `save_outputs(outputs)`: Same as `save_pages(pages)` but for outputs

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

  # custom variables passed from previous page
  "vars": {
    "category": "Food Cupboard",
    "category_id": "1234"
  }


  # Processing Metrics
  "parsing_try_count": 3,
  "parsing_fail_count": 3,
  "fetching_try_count": 1,
  
  # Some unimportant data
  "response_checksum": "9d650deb8d3fd908de452f27e148293d",
  "response_status": "200 OK",
  "response_status_code": 200,
  "response_proto": "HTTP/1.1",
  "content_type": "text/html; charset=utf-8",
  "content_size": 555,
  "no_redirect": false,
  "ua_type": "desktop",
  "force_fetch": false,
  "created_at": "2019-08-09T21:44:18.709737Z",
  "parsing_at": null,
  "parsing_failed_at": "2019-08-09T22:05:30.684121Z",
  "parsed_at": null,
  "fetched_at": "2019-08-09T21:45:10.312099Z",
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

# Save outputs into a collection
outputs << {
  '_collection': 'collection_name', # Required. 
  '_id': "an_identifier",           # Required. This is For deduplication, use something unique about the scraped data (e.g. product id, some identifier, etc) 
  'field1': data1,
  'field2': data2,
}

# Memory management only if we're accumulating pages or outputs inside a loop
save_pages(pages) if pages.count > 99
save_outputs(outputs) if outputs.count > 99
```



### 4. Finisher
- Post-processing after job completion
- Common uses:
  - Generate summaries
  - Run QA checks
  - Validate scraped data

### 5. Exporters 
- Export data to various formats from an output collection
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
- Strongly  recommended to include `_id` field to prevent duplication
- Metadata fields start with `_`
- Support multiple collections per scraper

### Error Handling
- Use conditional checks (`&.`)
- Handle missing elements gracefully
- Always include rescue clauses
- Validate data before saving

## Configuration (config.yaml)
```yaml
seeder:
  file: ./seeder/seeder.rb
  disabled: false # optional
  
parsers:
  - page_type: listings
    file: ./parsers/listings.rb
    disabled: false # optional
  - page_type: details 
    file: ./parsers/details.rb
    
finisher:
  file: ./finisher/finisher.rb
  disabled: false # optional

exporters:
  - file: ./exporters/data.yaml
    disabled: false # optional
   
```

This comprehensive guide covers the essential components and concepts for building DataHen scrapers, including detailed configuration options, memory management, and best practices for handling different types of pages and data extraction scenarios.