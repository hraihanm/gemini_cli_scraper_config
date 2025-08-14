# Autorefetch utility for handling failed pages
# Based on production scraper patterns

def autorefetch(reason = "Failed page")
  puts "Autorefetch triggered: #{reason}"
  
  # Re-queue the current page for fetching
  pages << {
    url: page['url'],
    method: page['method'] || 'GET',
    page_type: page['page_type'],
    headers: page['headers'] || ReqHeaders::DEFAULT_HEADER,
    fetch_type: page['fetch_type'] || 'browser',
    priority: (page['priority'] || 100) - 10,  # Lower priority for retries
    vars: page['vars'],
    driver: { name: "autorefetch_#{rand(1000)}" }
  }
  
  # Finish current parsing to avoid duplicate processing
  finish
end
