#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# DataHen V3 Local Runner
# =============================================================================
# Run scrapers locally without deploying to DataHen.
#
# Usage:
#   ruby local_runner.rb -s <scraper_dir> seed
#   ruby local_runner.rb -s <scraper_dir> step [--page-type <type>] [--count <n>]
#   ruby local_runner.rb -s <scraper_dir> status
#   ruby local_runner.rb -s <scraper_dir> reset
#
# Browser fetch support:
#   Pages with fetch_type: 'browser' or 'playwright' are forwarded to the
#   scraping dashboard's browser proxy (POST /api/browser-fetch).
#   Start the dashboard first: node lib/scraping_dashboard.js -s <scraper_dir>
#   Or set DATAHEN_DASHBOARD_PORT env var (default: 4567).
# =============================================================================

require 'json'
require 'yaml'
require 'fileutils'
require 'net/http'
require 'uri'
require 'digest'
require 'time'
require 'optparse'
require 'nokogiri'

class LocalRunner
  STATE_DIR = '.local-state'
  QUEUE_FILE = '.local-state/queue.json'
  OUTPUTS_DIR = '.local-state/outputs'
  CACHE_DIR = '.local-state/cache'

  def initialize(scraper_dir, opts = {})
    @scraper_dir = File.expand_path(scraper_dir)
    @dashboard_port = opts[:dashboard_port] || ENV.fetch('DATAHEN_DASHBOARD_PORT', '4567').to_i
    @quiet = opts[:quiet] || false
    @config = load_config
    ensure_dirs
  end

  # -------------------------------------------------------------------------
  # Public commands
  # -------------------------------------------------------------------------

  def seed
    log "=== Seed ==="
    seeder_file = @config.dig('seeder', 'file')
    raise "No seeder defined in config.yaml" unless seeder_file

    seeder_path = File.join(@scraper_dir, seeder_file.sub(/^\.\//, ''))
    raise "Seeder not found: #{seeder_path}" unless File.exist?(seeder_path)

    pages_added = []
    run_script(seeder_path) do |result_pages, _outputs|
      pages_added = result_pages
    end

    queue = load_queue
    pages_added.each do |p|
      p['gid'] ||= generate_gid(p['url'] || '', p['method'] || 'GET')
      p['status'] = 'to_fetch'
      p['created_at'] ||= Time.now.iso8601
      queue << p unless queue.any? { |q| q['gid'] == p['gid'] }
    end
    save_queue(queue)
    log "Seeder added #{pages_added.length} page(s) to queue."
    pages_added.length
  end

  def step(page_type: nil, count: 1)
    log "=== Step (page_type=#{page_type || 'any'}, count=#{count}) ==="
    queue = load_queue

    candidates = queue.select { |p| p['status'] == 'to_fetch' }
    candidates = candidates.select { |p| p['page_type'] == page_type } if page_type
    candidates = candidates.first(count)

    if candidates.empty?
      log "No pages to fetch#{page_type ? " for page_type=#{page_type}" : ''}."
      return 0
    end

    processed = 0
    candidates.each_with_index do |page_obj, i|
      log "[#{i + 1}/#{candidates.length}] #{page_obj['page_type']} | #{page_obj['url']}"

      # Mark as fetching
      page_obj['status'] = 'fetching'
      save_queue(queue)

      begin
        html = fetch_content(page_obj)
        page_obj['status'] = 'fetched'
        save_queue(queue)

        new_pages, new_outputs = run_parser(page_obj, html)

        # Merge new pages into queue (deduplicate by gid)
        new_pages.each do |np|
          np['gid'] ||= generate_gid(np['url'] || '', np['method'] || 'GET')
          np['status'] = 'to_fetch'
          np['created_at'] ||= Time.now.iso8601
          queue << np unless queue.any? { |q| q['gid'] == np['gid'] }
        end

        # Save outputs by collection
        save_outputs(new_outputs)

        page_obj['status'] = 'parsed'
        page_obj['parsed_at'] = Time.now.iso8601
        log "  -> +#{new_pages.length} pages, +#{new_outputs.length} outputs"
        processed += 1
      rescue => e
        page_obj['status'] = 'failed'
        page_obj['error'] = e.message
        log "  !! Error: #{e.message}"
        log "     #{e.backtrace.first}"
      ensure
        save_queue(queue)
      end
    end

    processed
  end

  def status
    queue = load_queue
    outputs_summary = {}

    outputs_dir = File.join(@scraper_dir, OUTPUTS_DIR)
    if Dir.exist?(outputs_dir)
      Dir.glob(File.join(outputs_dir, '*.json')).each do |f|
        collection = File.basename(f, '.json')
        begin
          data = JSON.parse(File.read(f))
          outputs_summary[collection] = data.length
        rescue
          outputs_summary[collection] = 0
        end
      end
    end

    # Group queue by page_type × status
    by_type = queue.group_by { |p| p['page_type'] || 'unknown' }
    queue_summary = {}
    by_type.each do |type, pages|
      counts = pages.group_by { |p| p['status'] || 'unknown' }.transform_values(&:length)
      queue_summary[type] = counts
    end

    result = {
      queue_total: queue.length,
      queue_by_type: queue_summary,
      outputs: outputs_summary
    }
    puts JSON.pretty_generate(result)
    result
  end

  def reset
    log "=== Reset ==="
    state_path = File.join(@scraper_dir, STATE_DIR)
    if Dir.exist?(state_path)
      # Remove queue and outputs but keep cache
      FileUtils.rm_f(File.join(@scraper_dir, QUEUE_FILE))
      outputs_path = File.join(@scraper_dir, OUTPUTS_DIR)
      FileUtils.rm_rf(outputs_path)
      FileUtils.mkdir_p(outputs_path)
      log "Queue and outputs cleared (cache preserved)."
    else
      log "Nothing to reset."
    end
  end

  # -------------------------------------------------------------------------
  # Private
  # -------------------------------------------------------------------------
  private

  def load_config
    config_path = File.join(@scraper_dir, 'config.yaml')
    raise "config.yaml not found in #{@scraper_dir}" unless File.exist?(config_path)
    YAML.safe_load(File.read(config_path)) || {}
  end

  def ensure_dirs
    [STATE_DIR, OUTPUTS_DIR, CACHE_DIR].each do |dir|
      FileUtils.mkdir_p(File.join(@scraper_dir, dir))
    end
  end

  def load_queue
    path = File.join(@scraper_dir, QUEUE_FILE)
    return [] unless File.exist?(path)
    JSON.parse(File.read(path))
  rescue
    []
  end

  def save_queue(queue)
    path = File.join(@scraper_dir, QUEUE_FILE)
    File.write(path, JSON.pretty_generate(queue))
  end

  def save_outputs(new_outputs)
    by_collection = new_outputs.group_by { |o| o['_collection'] || 'outputs' }
    by_collection.each do |collection, items|
      path = File.join(@scraper_dir, OUTPUTS_DIR, "#{collection}.json")
      existing = File.exist?(path) ? JSON.parse(File.read(path)) : []
      items.each do |item|
        item_copy = item.reject { |k, _| k == '_collection' }
        existing << item_copy
      end
      File.write(path, JSON.pretty_generate(existing))
    end
  end

  def generate_gid(url, method = 'GET')
    Digest::MD5.hexdigest("#{method}:#{url}")
  end

  def fetch_content(page_obj)
    url = page_obj['url']
    method = (page_obj['method'] || 'GET').upcase
    gid = page_obj['gid'] ||= generate_gid(url, method)
    cache_file = File.join(@scraper_dir, CACHE_DIR, gid)

    if File.exist?(cache_file)
      log "  [cache] #{url}"
      return File.read(cache_file)
    end

    fetch_type = page_obj['fetch_type'] || 'standard'
    if %w[browser playwright].include?(fetch_type)
      fetch_via_browser(page_obj, cache_file)
    else
      fetch_via_http(page_obj, cache_file)
    end
  end

  def fetch_via_http(page_obj, cache_file)
    url = page_obj['url']
    method = (page_obj['method'] || 'GET').upcase
    log "  [http] #{method} #{url}"

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 30
    http.read_timeout = 60

    req_class = Net::HTTP.const_get(method.capitalize)
    request = req_class.new(uri)

    # Apply headers from page object
    headers = page_obj['headers'] || {}
    headers.each { |k, v| request[k] = v }
    request['User-Agent'] ||= 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'

    response = http.request(request)
    html = response.body.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
    File.write(cache_file, html)
    page_obj['fetched_from'] = 'web'
    page_obj['response_status_code'] = response.code.to_i
    html
  rescue => e
    log "  [http] Error: #{e.message}"
    raise
  end

  def fetch_via_browser(page_obj, cache_file)
    url = page_obj['url']
    log "  [browser] #{url}"

    dashboard_url = "http://localhost:#{@dashboard_port}/api/browser-fetch"
    uri = URI(dashboard_url)

    payload = {
      url: url,
      headers: page_obj['headers'] || {},
      method: page_obj['method'] || 'GET',
      body: page_obj['body']
    }

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 10
      http.read_timeout = 90

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(payload)

      response = http.request(request)
      result = JSON.parse(response.body)

      if result['error']
        raise "Browser fetch error: #{result['error']}"
      end

      html = result['html'] || ''
      File.write(cache_file, html)
      page_obj['fetched_from'] = 'browser'
      page_obj['response_status_code'] = result['status'] || 200
      html
    rescue Errno::ECONNREFUSED
      log "  [browser] WARNING: Dashboard not running on port #{@dashboard_port}."
      log "  [browser] Start it with: node lib/scraping_dashboard.js -s <scraper_dir>"
      log "  [browser] Falling back to HTTP fetch..."
      fetch_via_http(page_obj, cache_file)
    end
  end

  def find_parser(page_type)
    parsers = @config['parsers'] || []
    parser_cfg = parsers.find { |p| p['page_type'] == page_type && !p['disabled'] }
    return nil unless parser_cfg

    file = parser_cfg['file'].sub(/^\.\//, '')
    File.join(@scraper_dir, file)
  end

  def run_parser(page_obj, html)
    page_type = page_obj['page_type']
    parser_path = find_parser(page_type)
    raise "No parser found for page_type=#{page_type}" unless parser_path
    raise "Parser file not found: #{parser_path}" unless File.exist?(parser_path)

    result_pages = []
    result_outputs = []

    run_script(parser_path, page_obj: page_obj, html_content: html) do |pages, outputs|
      result_pages = pages
      result_outputs = outputs
    end

    [result_pages, result_outputs]
  end

  def run_script(script_path, page_obj: nil, html_content: nil)
    original_dir = Dir.pwd
    Dir.chdir(@scraper_dir)

    # Load lib files
    lib_dir = File.join(@scraper_dir, 'lib')
    if Dir.exist?(lib_dir)
      Dir.glob(File.join(lib_dir, '*.rb')).sort.each do |lib_file|
        begin
          load lib_file
        rescue => e
          log "  Warning: #{File.basename(lib_file)} - #{e.message}"
        end
      end
    end

    script_code = File.read(script_path)

    # Build the execution binding with DataHen pre-defined variables
    pages = []
    outputs = []

    if page_obj
      content = html_content || ''
      failed_content = nil
      page = build_page_var(page_obj, content)
      html = Nokogiri::HTML(content) if content && !content.empty?
    else
      # Seeder: only pages is available
      content = nil
      failed_content = nil
      page = nil
      html = nil
    end

    def finish; end
    def limbo(gid); end
    def save_outputs(arr); end

    ctx = binding
    eval(script_code, ctx)

    result_pages = ctx.local_variable_get(:pages) rescue []
    result_outputs = ctx.local_variable_get(:outputs) rescue []

    yield(result_pages, result_outputs) if block_given?
  rescue => e
    raise
  ensure
    Dir.chdir(original_dir)
  end

  def build_page_var(page_obj, content)
    url = page_obj['url'] || ''
    {
      'gid'                    => page_obj['gid'] || generate_gid(url),
      'parent_gid'             => page_obj['parent_gid'],
      'job_id'                 => 1,
      'status'                 => 'fetched',
      'fetch_type'             => page_obj['fetch_type'] || 'standard',
      'hostname'               => (URI(url).host rescue 'localhost'),
      'page_type'              => page_obj['page_type'] || 'details',
      'priority'               => page_obj['priority'] || 500,
      'method'                 => page_obj['method'] || 'GET',
      'url'                    => url,
      'effective_url'          => url,
      'headers'                => page_obj['headers'] || {},
      'cookie'                 => nil,
      'body'                   => page_obj['body'],
      'created_at'             => page_obj['created_at'] || Time.now.iso8601,
      'no_redirect'            => false,
      'no_url_encode'          => false,
      'no_default_headers'     => false,
      'custom_headers'         => false,
      'http2'                  => false,
      'fresh'                  => true,
      'fetched_from'           => page_obj['fetched_from'] || 'web',
      'response_status'        => "#{page_obj['response_status_code'] || 200} OK",
      'response_status_code'   => page_obj['response_status_code'] || 200,
      'response_headers'       => { 'Content-Type' => ['text/html; charset=UTF-8'] },
      'content_type'           => 'text/html; charset=UTF-8',
      'content_size'           => content.length,
      'vars'                   => page_obj['vars'] || {},
      'force_fetch'            => false
    }
  end

  def log(msg)
    return if @quiet
    puts msg
    $stdout.flush
  end
end

# =============================================================================
# CLI entry point
# =============================================================================

def main
  options = { count: 1 }

  op = OptionParser.new do |opts|
    opts.banner = "Usage: local_runner.rb -s <scraper_dir> <command> [options]"
    opts.separator ""
    opts.separator "Commands: seed, step, status, reset"
    opts.separator ""
    opts.on("-s", "--scraper DIR", "Path to scraper directory") { |v| options[:scraper] = v }
    opts.on("--page-type TYPE", "Page type to step (step command only)") { |v| options[:page_type] = v }
    opts.on("--count N", Integer, "Number of pages to step (default: 1)") { |v| options[:count] = v }
    opts.on("--dashboard-port PORT", Integer, "Dashboard port for browser fetch (default: 4567)") { |v| options[:dashboard_port] = v }
    opts.on("--quiet", "Suppress verbose output") { options[:quiet] = true }
    opts.on("-h", "--help") { puts opts; exit }
  end

  command = nil
  remaining = op.parse(ARGV)
  command = remaining.first

  unless options[:scraper]
    puts "Error: -s <scraper_dir> is required"
    puts "Usage: local_runner.rb -s <dir> <seed|step|status|reset>"
    exit 1
  end

  unless command
    puts "Error: command is required (seed, step, status, reset)"
    puts "Usage: local_runner.rb -s <dir> <seed|step|status|reset>"
    exit 1
  end

  runner = LocalRunner.new(options[:scraper], options)

  case command
  when 'seed'
    runner.seed
  when 'step'
    runner.step(page_type: options[:page_type], count: options[:count])
  when 'status'
    runner.status
  when 'reset'
    runner.reset
  else
    puts "Unknown command: #{command}"
    puts "Valid commands: seed, step, status, reset"
    exit 1
  end
end

main if __FILE__ == $0
