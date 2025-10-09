# Parser Generation Workflow

## Multi-Agent Parser Generation Process

### Phase 1: Site Analysis & Navigation Discovery
**Agent**: Navigation Agent
**Duration**: 10 minutes
**Tasks**:
- Analyze website structure using Playwright MCP tools
- Map category hierarchies and navigation patterns
- Identify pagination mechanisms and URL structures
- Document breadcrumb patterns and page relationships

**Output**: Complete site map with navigation patterns

### Phase 2: Selector Analysis & Verification
**Agent**: Selector Agent
**Duration**: 15 minutes
**Tasks**:
- Create CSS selectors for all required data fields
- Verify selectors using `browser_verify_selector` tool
- Test selectors across multiple page variations
- Create fallback selector strategies

**Output**: Verified CSS selectors with >90% accuracy

### Phase 3: Parser Development
**Agent**: Parser Agent
**Duration**: 15 minutes
**Tasks**:
- Create Ruby parsers using verified selectors
- Implement error handling and fallback strategies
- Add memory management with `save_pages`/`save_outputs`
- Test parsers with `parser_tester` MCP tool

**Output**: Production-ready Ruby parsers

### Phase 4: Integration Testing
**All Agents**: Coordination
**Duration**: 10 minutes
**Tasks**:
- Test complete scraping pipeline
- Verify data flow between parsers
- Validate variable passing and context preservation
- Perform cross-page testing

**Output**: Fully functional scraper ready for deployment

## Quality Gates

### Analysis Gate
- Navigation Agent must provide complete site map
- All navigation patterns must be documented
- URL structures must be clearly defined

### Selector Gate
- Selector Agent must achieve >90% verification rate
- All selectors must work across different page variations
- Fallback strategies must be implemented

### Parser Gate
- Parser Agent must pass parser_tester validation
- All parsers must include proper error handling
- Memory management must be implemented

### Integration Gate
- All components must work together seamlessly
- Data flow must be validated end-to-end
- Variable passing must be verified

## Success Criteria

- **Selector Accuracy**: >90% match rate
- **Data Extraction**: >95% of required fields
- **Error Handling**: Graceful handling of missing elements
- **Performance**: Complete workflow within 45 minutes
- **Production Ready**: Deployment-ready scrapers
