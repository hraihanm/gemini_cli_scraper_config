# frozen_string_literal: true

# ============================================================================
# Extraction — DHero Boilerplate (SHARED NORMALIZERS — generally NO edits needed)
# ============================================================================
#
# Reusable, site-agnostic helpers every dhero parser needs. Generalized from the
# production snoonu_qa / totersapp / lezzoo_iq scrapers so parsers stop
# re-deriving opening-hours / phone / price / cuisine / id logic each time.
#
# Use from a parser:
#   require './lib/extraction'
#   hours = Extraction.opening_hours_from_minutes(merchant['weekdayAvailabilities'])
#   price, original = Extraction.item_prices(menu)
#   id = Extraction.md5_id(restaurant_name, city, address)
# ============================================================================

require 'digest'
require 'time'

module Extraction
  DAY_KEYS = %w[Sun Mon Tue Wed Thu Fri Sat].freeze

  DAY_ABBR = {
    'monday' => 'Mon', 'mon' => 'Mon', 'tuesday' => 'Tue', 'tue' => 'Tue',
    'wednesday' => 'Wed', 'wed' => 'Wed', 'thursday' => 'Thu', 'thu' => 'Thu',
    'friday' => 'Fri', 'fri' => 'Fri', 'saturday' => 'Sat', 'sat' => 'Sat',
    'sunday' => 'Sun', 'sun' => 'Sun'
  }.freeze

  module_function

  # ---- value normalization ------------------------------------------------
  def str_empty_to_nil(str)
    return str unless str.is_a?(String)
    s = str.strip
    return nil if s.empty? || s == '.'
    s
  end

  def zero_to_nil(num)
    n = Float(num) rescue nil
    return nil if n.nil? || n.zero?
    n
  end

  # ---- ids ----------------------------------------------------------------
  # Stable MD5 hex id from any number of identifier parts (drops blanks).
  def md5_id(*parts)
    Digest::MD5.hexdigest(parts.compact.map(&:to_s).reject(&:empty?).join(','))
  end

  # MD5 reformatted as a dashed UUID-shaped string (lezzoo/totersapp style).
  def dashed_id(*parts)
    h = md5_id(*parts)
    "#{h[0..7]}-#{h[8..11]}-#{h[12..15]}-#{h[16..19]}-#{h[20..-1]}"
  end

  # RFC-4122 v3 UUID (totersapp namespace style).
  def uuid_v3(namespace, name)
    hash = Digest::MD5.new
    hash.update(namespace.to_s)
    hash.update(name.to_s)
    ary = hash.digest.unpack('NnnnnN')
    ary[2] = (ary[2] & 0x0FFF) | (3 << 12)
    ary[3] = (ary[3] & 0x3FFF) | 0x8000
    format('%08x-%04x-%04x-%04x-%04x%08x', *ary)
  end

  # ---- time / opening hours ----------------------------------------------
  def day_abbr(day)
    key = day.to_s.strip.downcase
    DAY_ABBR[key] || (day.to_s.strip[0..2].capitalize if day.to_s.strip.length >= 3)
  end

  # "9:00 AM" / "21:30" / "0930" → "HHMM"
  def to_hhmm(time_str)
    raw = time_str.to_s.strip
    return nil if raw.empty?
    if raw =~ /\A(\d{1,2}):(\d{2})\s*([AP]M)\z/i
      hour = Regexp.last_match(1).to_i
      minute = Regexp.last_match(2).to_i
      meridian = Regexp.last_match(3).upcase
      hour = 0 if hour == 12 && meridian == 'AM'
      hour += 12 if meridian == 'PM' && hour != 12
      return format('%02d%02d', hour, minute)
    end
    return format('%02d%02d', Regexp.last_match(1).to_i, Regexp.last_match(2).to_i) if raw =~ /\A(\d{1,2}):(\d{2})\z/
    digits = raw.delete(':')
    digits.empty? ? nil : digits
  end

  def format_time_range(from_t, to_t)
    f = to_hhmm(from_t)
    t = to_hhmm(to_t)
    return nil if f.nil? || t.nil?
    "#{f}-#{t}"
  end

  # Minutes-from-midnight schedule (snoonu weekdayAvailabilities) → day-keyed hash.
  # Entries: [{ 'day' => 0..6 (0=Sun), 'openingTime' => Int, 'closingTime' => Int }]
  # Handles ranges that cross midnight by splitting onto the next day.
  def opening_hours_from_minutes(entries)
    hours = {}
    Array(entries).each do |h|
      day = h['day']
      open_min = h['openingTime']
      close_min = h['closingTime']
      next if day.nil? || open_min.nil? || close_min.nil?

      open_str = format('%02d%02d', open_min / 60, open_min % 60)
      if close_min > 1440
        co = close_min - 1440
        (hours[DAY_KEYS[day]] ||= []) << "#{open_str}-2400"
        nxt = day + 1 > 6 ? 0 : day + 1
        (hours[DAY_KEYS[nxt]] ||= []) << "0000-#{format('%02d%02d', co / 60, co % 60)}"
      else
        (hours[DAY_KEYS[day]] ||= []) << "#{open_str}-#{format('%02d%02d', close_min / 60, close_min % 60)}"
      end
    end
    hours.each_value(&:uniq!)
    hours.empty? ? nil : hours
  end

  # Generic schedule normalizer (totersapp style) — accepts a Hash keyed by day,
  # or an Array of {days/day, slots/time_ranges/...} entries. Returns
  # { 'Mon' => ['HHMM-HHMM'], ... } or nil.
  def opening_hours_generic(schedule)
    return nil if schedule.nil?
    hours = {}
    add = lambda do |day, slot|
      abbr = day_abbr(day)
      return if abbr.nil?
      range =
        case slot
        when String
          parts = slot.split(/\s*-\s*/, 2)
          parts.size == 2 ? format_time_range(parts[0], parts[1]) : nil
        when Hash
          format_time_range(slot['from'] || slot['opens'] || slot['open'] || slot['start'],
                            slot['to'] || slot['closes'] || slot['close'] || slot['end'])
        end
      return if range.nil?
      (hours[abbr] ||= []) << range unless (hours[abbr] || []).include?(range)
    end

    case schedule
    when Hash
      schedule.each { |day, slots| Array(slots).each { |s| add.call(day, s) } }
    when Array
      schedule.each do |entry|
        next unless entry.is_a?(Hash)
        days = entry['days'] || entry['day'] || entry['day_of_week'] || entry['weekday']
        days = [days] unless days.is_a?(Array)
        slots = entry['slots'] || entry['time_ranges'] || entry['timeRanges'] || entry['hours'] || entry['schedule']
        slots = [entry] if slots.nil? && (entry.key?('from') || entry.key?('opens') || entry.key?('start'))
        days.each { |d| Array(slots).each { |s| add.call(d, s) } }
      end
    end
    hours.empty? ? nil : hours
  end

  # ---- phone --------------------------------------------------------------
  # raw → "+<dial><digits>". Pass the project dial code (e.g. '974').
  def format_phone(raw_phone, dial_code: nil)
    phone = raw_phone.to_s.strip
    return nil if phone.empty?
    return phone if phone.start_with?('+')
    return phone if dial_code.nil?
    digits = phone.gsub(/\D/, '')
    digits.empty? ? phone : "+#{dial_code}#{digits}"
  end

  # ---- prices -------------------------------------------------------------
  # Returns [item_price, original_price]. item_price is current (discounted)
  # price; original_price is pre-promo (nil when not on promotion).
  # Tries common API key spellings; treats <= 0 as nil.
  def item_prices(menu)
    price = positive_float(menu['price']) ||
            positive_float(menu['product_price']) ||
            positive_float(menu['unit_price']) ||
            positive_float(menu['minPrice']) ||
            positive_float(menu['min_price']) ||
            positive_float(menu['price_without_discount'])
    original = positive_float(menu['price_old']) ||
               positive_float(menu['original_price']) ||
               positive_float(menu['price_without_discount'])
    # If a discounted price exists, prefer it as current.
    discounted = positive_float(menu['discount_price']) ||
                 positive_float(menu['product_discount_price']) ||
                 positive_float(menu['salePrice'])
    if discounted && price && discounted < price
      original = price
      price = discounted
    end
    original = nil if original && price && original <= price
    [price, original]
  end

  def positive_float(val)
    f = Float(val) rescue nil
    f && f > 0 ? f : nil
  end

  def promoted?(price, original_price)
    return false if price.nil? || original_price.nil?
    price < original_price
  end

  # ---- cuisine ------------------------------------------------------------
  # Array of cuisine strings → { 'cuisine1' => 'Pizza', 'cuisine2' => 'Burger' }.
  # Returns nil when empty (matches A2 expectation when truly absent).
  def cuisine_hash(list)
    arr = Array(list).map { |c| c.to_s.strip }.reject(&:empty?)
    return nil if arr.empty?
    arr.each_with_index.each_with_object({}) { |(c, i), h| h["cuisine#{i + 1}"] = c }
  end

  # ---- geo ----------------------------------------------------------------
  # city_zones: [[name, min_lat, max_lat, min_lng, max_lng], ...]
  def city_from_coordinates(lat, lng, city_zones)
    lat_f = Float(lat) rescue nil
    lng_f = Float(lng) rescue nil
    return nil if lat_f.nil? || lng_f.nil? || lat_f.zero? || lng_f.zero?
    Array(city_zones).each do |city, min_lat, max_lat, min_lng, max_lng|
      return city if lat_f.between?(min_lat, max_lat) && lng_f.between?(min_lng, max_lng)
    end
    nil
  end
end
