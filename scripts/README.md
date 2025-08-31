# Parser Tester Scripts

These scripts mimic the functionality of `hen parser try` by allowing you to test DataHen parser scripts against specific URLs without needing the full DataHen environment.

## What These Scripts Do

1. **Fetch a webpage** using the provided URL OR **Load HTML from local file**
2. **Mock the DataHen environment** variables (`content`, `page`, `html`, `failed_content`)
3. **Execute your parser script** with the mocked variables
4. **Display the results** showing both `pages` and `outputs` arrays
5. **Cache management** for downloaded HTML pages

## Available Scripts

### 1. Ruby Script (Cross-platform)
- **File**: `parser_tester.rb`
- **Requirements**: Ruby with `nokogiri` gem
- **Best for**: Most reliable execution, direct Ruby compatibility, HTML file testing, caching

### 2. PowerShell Script (Windows)
- **File**: `parser_tester.ps1`
- **Requirements**: PowerShell 5.1+, Ruby installed
- **Best for**: Windows users who prefer PowerShell

### 3. Bash Script (Unix/Linux/macOS)
- **File**: `parser_tester.sh`
- **Requirements**: Bash, Ruby, `jq` (optional, for JSON formatting)
- **Best for**: Unix/Linux/macOS users

## Installation

### Prerequisites
- Ruby installed on your system
- Nokogiri gem: `gem install nokogiri`

### For Windows Users
- Install Ruby from https://rubyinstaller.org/
- Install Nokogiri: `gem install nokogiri`

### For Unix/Linux/macOS Users
- Install Ruby: `sudo apt-get install ruby` (Ubuntu/Debian) or `brew install ruby` (macOS)
- Install Nokogiri: `gem install nokogiri`
- Install jq (optional): `sudo apt-get install jq` or `brew install jq`

## Usage

### Ruby Script
```bash
# Basic usage with scraper directory and URL
ruby parser_tester.rb -s "./generated_scraper/naivas_ke_nairobi" -p "parsers/details.rb" -u "https://example.com/product/123"

# Test with local HTML file (recommended for reliable testing)
ruby parser_tester.rb -s "./generated_scraper/naivas_ke_nairobi" -p "parsers/details.rb" --html "./cache/product-page.html"

# Test with vars only (no URL)
ruby parser_tester.rb -s "./generated_scraper/naivas_ke_nairobi" -p "parsers/listings.rb" -v '{"category":"electronics"}'

# With help
ruby parser_tester.rb -h
```

### PowerShell Script
```powershell
# Basic usage
.\parser_tester.ps1 -Url "https://example.com/product/123" -ParserPath "parsers/details.rb"

# With help
.\parser_tester.ps1 -Help
```

### Bash Script
```bash
# Make executable first
chmod +x parser_tester.sh

# Basic usage
./parser_tester.sh "https://example.com/product/123" "parsers/details.rb"
```

## Example Output

The script will output similar to `hen parser try`:

**Testing with URL**:
```
=== Parser Tester ===
✓ Using URL: https://example.com/product/123
✓ Page fetched: 15420 characters
✓ Parser executed successfully

=== Results ===
Outputs (1):
[
  {
    "_collection": "products",
    "_id": "12345",
    "name": "Product Name",
    "price": "29.99",
    ...
  }
]
```

**Testing with HTML file**:
```
=== Parser Tester ===
✓ HTML loaded: 15420 characters
✓ Parser executed successfully

=== Results ===
Outputs (1):
[
  {
    "_collection": "products",
    "_id": "12345",
    "name": "Product Name",
    "price": "29.99",
    ...
  }
]
```

**Testing with vars only**:
```
=== Parser Tester ===
✓ Using vars for testing: {"category"=>"electronics"}
✓ Parser executed successfully

=== Results ===
Pages (15):
[...]
```

## How It Works

1. **Content Fetching**: Uses standard HTTP requests to fetch the webpage OR loads from local HTML file
2. **Environment Mocking**: Creates mock `page`, `content`, and `failed_content` variables that match DataHen's structure
3. **Parser Execution**: Loads and executes your parser script in a controlled environment
4. **Result Capture**: Captures the `pages` and `outputs` arrays from your parser
5. **Output Display**: Shows the results in a clean, organized format
6. **Caching**: Automatically caches downloaded HTML for faster subsequent testing

## Mocked Variables

The scripts provide these variables to your parser:

- `content`: The HTML content of the fetched page (or `nil` if fetch failed)
- `failed_content`: The HTML content if the fetch failed (or `nil` if successful)
- `page`: A comprehensive hash containing:
  - `url`: The URL being tested
  - `method`: HTTP method (GET)
  - `page_type`: Default "details" (can be overridden)
  - `fetched_at`: Current timestamp
  - `response_status_code`: 200 (success) or 500 (failure)
  - `gid`: Generated from URL hash
  - `refetch_count`: 0
  - `priority`: 500 (can be overridden)
  - `fetch_type`: "browser"
  - `headers`: Standard browser headers
  - `vars`: Empty hash (can be populated by your parser)
  - `job_id`: 12345 (can be overridden)
  - And many more DataHen-compatible fields
- `html`: Nokogiri HTML object for easy parsing (only if content exists)
- `pages`: Array for queuing new pages
- `outputs`: Array for storing extracted data

## Use Cases

- **Development**: Test parsers during development without deploying to DataHen
- **Debugging**: Isolate parser issues from DataHen environment problems
- **Testing**: Verify parser logic against live websites or cached HTML
- **Validation**: Check that selectors work correctly before deployment
- **Offline Testing**: Test parsers with downloaded HTML files for reliable results
- **Caching**: Store HTML pages for faster testing iterations

## Limitations

- **No DataHen Environment**: Some DataHen-specific functions may not work
- **Single Page Testing**: Tests one URL or HTML file at a time
- **No Database**: Results are not stored permanently
- **Limited Headers**: Uses standard browser headers, may not match your production setup
- **Cache Storage**: HTML files are stored locally in `cache/` directory

## Troubleshooting

### Common Issues

1. **"command not found: ruby"**
   - Install Ruby on your system
   - Ensure Ruby is in your PATH

2. **"cannot load such file -- nokogiri"**
   - Install Nokogiri: `gem install nokogiri`

3. **Parser errors**
   - Check that your parser file exists and is valid Ruby
   - Ensure all required gems are installed
   - Check for syntax errors in your parser

4. **Network errors**
   - Verify the URL is accessible
   - Check your internet connection
   - Some sites may block automated requests

### Getting Help

- Check that all prerequisites are installed
- Verify your parser file syntax
- Test with a simple, accessible URL first
- Check the error messages for specific issues

## Integration with Gemini CLI

These scripts can be easily integrated with Gemini CLI by:

1. **Adding to your project**: Place the scripts in your project's `scripts/` directory
2. **Making them executable**: Ensure proper permissions
3. **Using in workflows**: Call them from other automation scripts
4. **Customizing**: Modify the scripts to match your specific needs
5. **Enhanced Workflow**: Use with browser tools to download HTML and test parsers automatically

## Advanced Usage

### HTML File Testing
Test parsers with downloaded HTML files for reliable, offline testing:
```bash
# Download HTML first, then test
ruby parser_tester.rb -s "./scraper" -p "parsers/details.rb" --html "./cache/page.html"
```

### Cache Management
Use built-in cache management commands:
```bash
# List cached pages
ruby parser_tester.rb --list-cache

# Clear all cached pages
ruby parser_tester.rb --clear-cache
```

### Custom Headers
Modify the scripts to include custom headers for your specific use case.

### Environment Variables
Set environment variables to customize behavior:
- `PARSER_TIMEOUT`: Set HTTP timeout
- `USER_AGENT`: Custom user agent string
- `DEBUG`: Enable verbose output

### Batch Testing
Create wrapper scripts to test multiple URLs or parsers in sequence.

### Enhanced Options
- `--page-type`: Override default page type
- `--priority`: Set custom page priority
- `--job-id`: Set custom job ID
- `--quiet`: Suppress verbose output for cleaner results
