# Parser Tester Example Usage

This document shows how to use the `parser_tester.rb` script with the new workflow that generates code in the `./generated_scraper` folder.

## Prerequisites

1. **Ruby installed** with `nokogiri` gem
2. **Generated scraper folder** in `./generated_scraper/[scraper_name]/`
3. **Parser files** in the scraper directory

## Setup

1. **Create your scraper directory**:
   ```bash
   mkdir -p ./generated_scraper/my_scraper
   cd ./generated_scraper/my_scraper
   ```

2. **Create the standard DataHen structure**:
   ```bash
   mkdir -p parsers seeder finisher
   touch config.yaml
   ```

3. **Create a sample parser** (e.g., `parsers/details.rb`):
   ```ruby
   # parsers/details.rb
   html = Nokogiri::HTML(content)
   
   # Extract product information
   name = html.at_css('h1.product-title')&.text&.strip || 'Unknown Product'
   price = html.at_css('.price')&.text&.strip || '0.00'
   
   # Create output
   outputs << {
     '_collection' => 'products',
     '_id' => page['gid'],
     'name' => name,
     'price' => price,
     'url' => page['url']
   }
   ```

## Testing with Parser Tester

### 1. Test with URL (Recommended for details parsers)

```bash
# From the project root directory
ruby scripts/parser_tester.rb \
  -s "./generated_scraper/my_scraper" \
  -p "parsers/details.rb" \
  -u "https://example.com/product/123"
```

**What happens**:
- Fetches the webpage content
- Creates mock `page` variable with the URL
- Executes your parser
- Shows outputs and any new pages queued

### 2. Test with Vars (Good for listings parsers)

```bash
# Test with predefined variables
ruby scripts/parser_tester.rb \
  -s "./generated_scraper/my_scraper" \
  -p "parsers/listings.rb" \
  -v '{"category":"electronics","page":1}'
```

**What happens**:
- Uses test HTML content
- Creates mock `page` variable with your vars
- Executes your parser
- Shows outputs and any new pages queued

### 3. Test from within scraper directory

```bash
# Navigate to scraper directory first
cd ./generated_scraper/my_scraper

# Then test (using relative paths)
ruby ../../scripts/parser_tester.rb \
  -s . \
  -p "parsers/details.rb" \
  -u "https://example.com/product/123"
```

## Expected Output

```
Trying parser script
Getting Job Page
Using URL: https://example.com/product/123
Page content fetched successfully (15420 characters)
=========== Parsing Executed ===========
----------------------------------------
Trying to validate 1 out of 1 Outputs
[
  {
    "_collection": "products",
    "_id": "abc123",
    "name": "Sample Product",
    "price": "29.99",
    "url": "https://example.com/product/123"
  }
]
Validation successful
```

## Integration with DataHen CLI

After testing with `parser_tester.rb`, you can use the full DataHen CLI:

```bash
# Navigate to scraper directory
cd ./generated_scraper/my_scraper

# Test with DataHen CLI
hen parser try my_scraper parsers/details.rb "https://example.com/product/123"

# Deploy when ready
hen scraper deploy my_scraper
```

## Troubleshooting

### Common Issues

1. **"Scraper directory not found"**
   - Ensure the path to `./generated_scraper/[scraper_name]` is correct
   - Check that the directory exists and contains `config.yaml`

2. **"Parser file not found"**
   - Verify the parser path is relative to the scraper directory
   - Example: `parsers/details.rb` not `./generated_scraper/my_scraper/parsers/details.rb`

3. **"config.yaml not found"**
   - Ensure `config.yaml` exists in the scraper directory
   - This file is required to validate the scraper structure

### Best Practices

1. **Always test with `parser_tester.rb` first** - faster iteration
2. **Use DataHen CLI for final validation** - full environment testing
3. **Keep scraper projects organized** in `./generated_scraper/[scraper_name]/`
4. **Test both URL and vars scenarios** to ensure parser robustness

## Workflow Summary

1. **Create scraper** in `./generated_scraper/[scraper_name]/`
2. **Develop parsers** using `parser_tester.rb` for quick testing
3. **Validate with DataHen CLI** before deployment
4. **Deploy and monitor** using DataHen platform

This workflow ensures fast development cycles while maintaining production quality standards.
