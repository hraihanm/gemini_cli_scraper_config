# Parser Tester Scripts

These scripts mimic the functionality of `hen parser try` by allowing you to test DataHen parser scripts against specific URLs without needing the full DataHen environment.

## What These Scripts Do

1. **Fetch a webpage** using the provided URL
2. **Mock the DataHen environment** variables (`content`, `page`, `html`)
3. **Execute your parser script** with the mocked variables
4. **Display the results** showing both `pages` and `outputs` arrays

## Available Scripts

### 1. Ruby Script (Cross-platform)
- **File**: `parser_tester.rb`
- **Requirements**: Ruby with `nokogiri` gem
- **Best for**: Most reliable execution, direct Ruby compatibility

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
# Basic usage with scraper directory
ruby parser_tester.rb -s "./generated_scraper/naivas_ke_nairobi" -p "parsers/details.rb" -u "https://example.com/product/123"

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
    "_id": "12345",
    "name": "Product Name",
    "price": "29.99",
    ...
  }
]
Validation successful
```

**Testing with vars only**:
```
Trying parser script
Getting Job Page
Using vars for testing: {"category"=>"electronics"}
=========== Parsing Executed ===========
----------------------------------------
Trying to validate 15 out of 15 Pages
[...]
Validation successful
```

## How It Works

1. **Content Fetching**: Uses standard HTTP requests to fetch the webpage
2. **Environment Mocking**: Creates mock `page` and `content` variables that match DataHen's structure
3. **Parser Execution**: Loads and executes your parser script in a controlled environment
4. **Result Capture**: Captures the `pages` and `outputs` arrays from your parser
5. **Output Display**: Shows the results in the same format as `hen parser try`

## Mocked Variables

The scripts provide these variables to your parser:

- `content`: The HTML content of the fetched page
- `page`: A hash containing:
  - `url`: The URL being tested
  - `method`: HTTP method (GET)
  - `page_type`: Default "details"
  - `fetched_at`: Current timestamp
  - `response_status_code`: 200
  - `gid`: Generated from URL hash
  - `refetch_count`: 0
  - `priority`: 100
  - `fetch_type`: "browser"
  - `headers`: Standard browser headers
  - `vars`: Empty hash (can be populated by your parser)
- `html`: Nokogiri HTML object for easy parsing
- `pages`: Array for queuing new pages
- `outputs`: Array for storing extracted data

## Use Cases

- **Development**: Test parsers during development without deploying to DataHen
- **Debugging**: Isolate parser issues from DataHen environment problems
- **Testing**: Verify parser logic against live websites
- **Validation**: Check that selectors work correctly before deployment

## Limitations

- **No DataHen Environment**: Some DataHen-specific functions may not work
- **Single Page Testing**: Tests one URL at a time
- **No Database**: Results are not stored permanently
- **Limited Headers**: Uses standard browser headers, may not match your production setup

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

## Advanced Usage

### Custom Headers
Modify the scripts to include custom headers for your specific use case.

### Environment Variables
Set environment variables to customize behavior:
- `PARSER_TIMEOUT`: Set HTTP timeout
- `USER_AGENT`: Custom user agent string
- `DEBUG`: Enable verbose output

### Batch Testing
Create wrapper scripts to test multiple URLs or parsers in sequence.
