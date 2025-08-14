require "./lib/headers"

# Production seeder template - seeds the main category page
# This will be customized based on the provided URL

pages << {
  url: "MAIN_PAGE_URL_PLACEHOLDER",  # Will be replaced with actual URL
  page_type: "category",
  http2: true,
  fetch_type: "browser",
  method: "GET",
  headers: ReqHeaders::DEFAULT_HEADER,
  priority: 1000
}
