# frozen_string_literal: true

# ============================================================================
# Extraction — dmart / greenfield boilerplate (SHARED NORMALIZERS)
# ============================================================================
# Reusable, site-agnostic helpers for product data extraction. Mirrors the
# dhero extraction.rb pattern so both pipelines share the same conventions.
#
# Usage in a parser:
#   require './lib/extraction'
#   json_ld  = Extraction.json_ld_for_type(html, 'Product', 'ItemPage')
#   price    = Extraction.price_from(text)
#   img      = Extraction.og_value(html, 'og:image')
#   prod_id  = Extraction.md5_id(url)
# ============================================================================

require 'digest'
require 'json'

module Extraction
  module_function

  # ---- value normalization --------------------------------------------------

  def str_empty_to_nil(str)
    return str unless str.is_a?(String)
    s = str.strip
    return nil if s.empty? || s == '.' || s == '{}' || s == '[]'
    s
  end

  def zero_to_nil(num)
    n = Float(num) rescue nil
    return nil if n.nil? || n.zero?
    n
  end

  # ---- ids ------------------------------------------------------------------

  def md5_id(*parts)
    Digest::MD5.hexdigest(parts.compact.map(&:to_s).reject(&:empty?).join(','))
  end

  # ---- JSON-LD --------------------------------------------------------------

  # Return the first parsed JSON-LD block whose @type matches one of *types.
  # Handles both single objects and @graph arrays.
  def json_ld_for_type(html, *types)
    html.css('script[type="application/ld+json"]').lazy.map { |s|
      begin
        parsed = JSON.parse(s.text)
        candidates = parsed.is_a?(Hash) && parsed['@graph'].is_a?(Array) ? parsed['@graph'] : [parsed]
        candidates.find { |c| c.is_a?(Hash) && types.include?(c['@type']) }
      rescue JSON::ParserError
        nil
      end
    }.find(&:itself)
  end

  # ---- meta / og ------------------------------------------------------------

  # Read a <meta property="..." content="..."> or <meta name="..." content="..."> tag.
  def og_value(html, property)
    el = html.at_css("meta[property='#{property}']") ||
         html.at_css("meta[name='#{property}']")
    str_empty_to_nil(el&.[]('content'))
  end

  # ---- prices ---------------------------------------------------------------

  # Strip currency symbols/separators, return Float or nil.
  # divisor: divide result (e.g. 100 when source is in pence/cents).
  def price_from(text, divisor: 1)
    return nil if text.nil?
    cleaned = text.to_s.gsub(/[^\d.]/, '')
    return nil if cleaned.empty?
    val = cleaned.to_f / divisor
    val.zero? ? nil : val.round(2)
  end

  # Return [current_price, original_price] from a pair of text values.
  # current_price is the discounted price when on promotion.
  def price_pair(current_text, original_text, divisor: 1)
    current  = price_from(current_text,  divisor: divisor)
    original = price_from(original_text, divisor: divisor)
    original = nil if original && current && original <= current
    [current, original]
  end

  # ---- stock / availability -------------------------------------------------

  def in_stock?(text)
    return true if text.nil?
    !text.to_s.match?(/out.?of.?stock|sold.?out|unavailable|épuisé/i)
  end

  # ---- URLs -----------------------------------------------------------------

  def fix_image_url(url, base_url:)
    return nil if url.nil? || url.to_s.strip.empty?
    return url if url.start_with?('http')
    "#{base_url}#{url.start_with?('/') ? url : '/' + url}"
  end

  def encode_url_path(url)
    url.to_s.gsub(/[^[:ascii:]]/) { |c|
      c.force_encoding('utf-8').bytes.map { |b| "%%%02X" % b }.join
    }
  end

  # ---- text cleanup ---------------------------------------------------------

  def clean_html_description(html_str)
    return nil if html_str.nil?
    text = html_str.to_s
      .gsub('&nbsp;', ' ').gsub('&ndash;', '-').gsub('&amp;', '&')
      .gsub(/<h[1-6][^>]*>(.*?)<\/h[1-6]>/m) { "\n#{$1.strip}\n" }
      .gsub(/<li[^>]*>(.*?)<\/li>/m)          { "• #{$1.strip}\n" }
      .gsub(/<br\s*\/?>/i, "\n")
      .gsub(/<[^>]+>/, '')
      .gsub(/\n{3,}/, "\n\n")
      .strip
    text.empty? ? nil : text
  end
end
