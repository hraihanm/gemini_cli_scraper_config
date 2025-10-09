---
marp: true
theme: default
paginate: true
---

# GEMINI.md Updates — Custom Slash Commands & Aiconfig Mode

## 🎯 What's New
- **Aiconfig Mode**: Alternative to exploration mode using structured configuration
- **Custom Slash Commands**: Streamlined workflows for parser generation
- **Enhanced Browser Automation**: Improved tool usage patterns

---

## 🔧 Aiconfig Mode vs Exploration Mode

### **Exploration Mode** (CSV-based)
- Start with CSV specification
- Generate parsers through iterative discovery
- Browser-first analysis approach
- Rapid prototyping workflow

### **Aiconfig Mode** (YAML-based)
- Start with structured `aiconfig.yaml` configuration
- Pre-defined field mappings and data structure
- Configuration-driven parser generation
- Production-ready approach

---

## 📋 Aiconfig.yaml Example

```yaml
# aiconfig.yaml - Agent Reference Only
seeder_pages:
  - url: "https://example.com/categories"
    page_type: "category"
    fields:
      - name: "category_name"
        type: "string"
        selector: ".category-title"
      - name: "product_count"
        type: "integer"
        selector: ".count"

outputs:
  product_details:
    fields:
      - name: "title"
        type: "string"
        required: true
      - name: "price"
        type: "float"
        required: true
      - name: "description"
        type: "text"
        required: false
```

**Note**: This is for agent reference, NOT the actual scraping system config

---

## ⚡ Custom Slash Commands

### **Main Commands**
- `/explore` - CSV-based parser generation
- `/aiconfig` - YAML-based parser generation

### **Subcommands**
- `/explore:analyze` - Page structure analysis
- `/explore:generate` - Parser code generation
- `/explore:test` - Parser validation
- `/aiconfig:analyze` - Configuration analysis
- `/aiconfig:generate` - Configuration-driven generation
- `/aiconfig:validate` - Scraper validation

---

## 🚀 Workflow Improvements

### **Browser Automation**
- **Preferred**: `auto_download: true` with `parser_tester`
- **Last Resort**: `browser_download_page()` only when needed
- **Efficient**: Direct browser state usage

### **Quality Standards**
- **Speed**: Site analysis within 5 minutes
- **Reliability**: 95%+ parser success rate
- **Coverage**: All pagination and subcategory patterns

---

## 🎨 Enhanced User Experience

### **Streamlined Workflows**
- One-command parser generation
- Automated testing and validation
- Clear error handling and fallbacks

### **Flexible Modes**
- Choose between CSV exploration or YAML configuration
- Adapt to different project requirements
- Maintain consistent quality standards

---

## 🔄 Integration with Existing System

### **Layered Configuration**
- **Strategic Layer**: `GEMINI.md` (high-level guidance)
- **Operational Layer**: `system.md` (tool usage rules)
- **Command Layer**: `.toml` files (specific workflows)

### **Backward Compatibility**
- Existing workflows remain unchanged
- New commands enhance, don't replace
- Gradual adoption possible

---

## 📈 Benefits

### **For Developers**
- Faster parser development
- Consistent quality standards
- Reduced manual configuration

### **For Projects**
- Better error handling
- Improved reliability
- Scalable architecture

---

## 🎯 Next Steps

- **Testing**: Validate new commands with real projects
- **Documentation**: Expand usage guides
- **Refinement**: Iterate based on feedback
- **Integration**: Seamless workflow adoption

---

## 💡 Key Takeaways

1. **Two Modes**: Choose CSV exploration or YAML configuration
2. **Custom Commands**: Streamlined workflows with `/explore` and `/aiconfig`
3. **Efficient Automation**: Smart browser tool usage patterns
4. **Quality Focus**: Consistent standards across all modes
5. **Future-Ready**: Extensible architecture for growth
