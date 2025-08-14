# Web Scraping Gemini CLI Setup Guide

This guide shows how to configure Gemini CLI as a specialized web scraping expert using the custom system prompt override feature.

## Quick Setup

### 1. Environment Configuration

Set the environment variable to use your custom system prompt:

**Windows (PowerShell):**
```powershell
$env:GEMINI_SYSTEM_MD = "true"
```

**Windows (Command Prompt):**
```cmd
set GEMINI_SYSTEM_MD=true
```

**macOS/Linux:**
```bash
export GEMINI_SYSTEM_MD=true
```

### 2. Verify Configuration

When the custom system prompt is active, you'll see the `|⌐■_■|` icon in the CLI footer, confirming the specialized configuration is loaded.

### 3. Test the Configuration

Try this command to verify the scraping expertise is active:
```bash
gemini "Analyze this e-commerce site structure and suggest a scraping approach"
```

## File Structure

Your project should have this structure:
```
your-project/
├── .gemini/
│   └── system.md          # Core operational rules (firmware layer)
├── GEMINI.md              # Web scraping expertise (strategic layer)
├── config.yaml            # DataHen V3 scraper configuration
├── seeder/
│   └── seeder.rb
├── parsers/
│   ├── categories.rb
│   ├── listings.rb
│   └── product.rb
└── finisher/
    └── finisher.rb
```

## Key Features Enabled

### 🎯 Specialized Persona
- Senior Web Scraping Engineer expertise
- DataHen V3 framework specialization
- Ruby and Nokogiri proficiency
- Advanced CSS selector engineering

### 🛠️ Enhanced Tool Integration
- Playwright MCP browser automation
- `browser_verify_selector` for selector validation
- `browser_inspect_element` for DOM analysis
- Batch element inspection capabilities

### 📋 Structured Methodology
- **PARSE Framework**: Plan → Analyze → Record → Script → Evaluate
- Systematic website analysis protocols
- Performance optimization strategies
- Quality assurance workflows

## Usage Examples

### Creating a New Scraper
```bash
gemini "Create a complete V3 scraper for an e-commerce site with categories, product listings, and product details"
```

### Selector Development
```bash
gemini "Help me find reliable CSS selectors for product prices on this page" --url https://example-store.com/product/123
```

### Optimization
```bash
gemini "Review my parser code and suggest performance optimizations"
```

### Troubleshooting
```bash
gemini "My product parser is missing some data fields. Help me debug and improve the extraction logic"
```

## Advanced Configuration

### Project-Specific Customization
You can further customize the behavior by modifying the `GEMINI.md` file to include:
- Specific website patterns you frequently scrape
- Custom data validation rules
- Company-specific coding standards
- Preferred libraries and tools

### Alternative System Prompt Path
Instead of using `GEMINI_SYSTEM_MD=true`, you can point to a specific file:
```bash
export GEMINI_SYSTEM_MD="/path/to/your/custom/system.md"
```

## Best Practices

### 1. Ethical Scraping
- Always respect robots.txt
- Implement appropriate delays
- Follow website terms of service
- Use proper user agent identification

### 2. Code Quality
- Include comprehensive error handling
- Use descriptive variable names
- Add meaningful comments
- Implement proper logging

### 3. Performance
- Batch save operations (every 99 items)
- Use efficient CSS selectors
- Implement proper pagination
- Monitor memory usage

### 4. Maintenance
- Regular selector validation
- Data quality monitoring
- Performance optimization reviews
- Documentation updates

## Troubleshooting

### Configuration Not Loading
1. Verify the `|⌐■_■|` icon appears in the CLI footer
2. Check that `.gemini/system.md` exists in your project root
3. Ensure `GEMINI_SYSTEM_MD` environment variable is set correctly

### Playwright MCP Not Available
1. Verify the MCP server is configured in your Gemini CLI settings
2. Check that the modded Playwright MCP is installed and running
3. Test browser tools with `gemini "Take a screenshot of google.com"`

### Performance Issues
1. Review parser code for inefficient selectors
2. Check for missing `save_pages`/`save_outputs` calls
3. Verify pagination logic doesn't create infinite loops
4. Monitor memory usage during large scraping jobs

## Getting Help

The specialized configuration includes comprehensive guidance, but you can also:
- Ask for specific scraping patterns: "Show me how to handle AJAX pagination"
- Request code reviews: "Review this parser for best practices"
- Get troubleshooting help: "Why is my selector not finding elements consistently?"
- Learn advanced techniques: "How do I handle dynamic content with JavaScript rendering?"

The AI will respond with expert-level web scraping knowledge and practical, tested solutions.
