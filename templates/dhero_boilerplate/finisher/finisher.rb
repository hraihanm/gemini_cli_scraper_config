# frozen_string_literal: true

# ============================================================================
# Finisher - DHero Boilerplate
# ============================================================================
#
# PURPOSE: Post-job pass over the `locations` collection — dedup near-identical
# restaurants and normalize a few fields. Modeled on the production
# lezzoo_iq / yummy_ve finishers.
#
# Disabled by default in config.yaml (finisher.disabled: true). Enable only when
# the source emits duplicate restaurants across pages/cities.
#
# DATAHEN v3 STRUCTURE:
# - TOP-LEVEL SCRIPT, NOT a function
# - Pre-defined: outputs
# - find_outputs(collection, query, page, per_page) for cursor pagination
# ============================================================================

per_page = 500
last_id  = ''
seen     = {}

loop do
  query = { '_id' => { '$gt' => last_id }, '$orderby' => [{ '_id' => 1 }] }
  records = find_outputs('locations', query, 1, per_page)
  break if records.nil? || records.empty?

  records.each do |loc|
    last_id = loc['_id']

    # Dedup on a stable natural key. Adjust the key parts per source if needed.
    key = [loc['restaurant_name'], loc['restaurant_city'], loc['restaurant_address']].join('|')
    next if seen[key]
    seen[key] = true

    # Light normalization (mirror production finishers).
    loc['restaurant_area'] = nil if loc['restaurant_area'].to_s.strip.empty?
    loc['phone_number']    = nil if loc['phone_number'].to_s.strip.empty?
    if loc['number_of_ratings'].to_s.strip.empty?
      loc['number_of_ratings'] = nil
    else
      n = loc['number_of_ratings'].to_i
      loc['number_of_ratings'] = n.zero? ? nil : n
    end

    outputs << loc
    save_outputs(outputs) if outputs.length > 99
  end
end

save_outputs(outputs)
warn "[FINISHER] locations deduped → #{seen.size} unique"
