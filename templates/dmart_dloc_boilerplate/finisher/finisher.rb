# frozen_string_literal: true

# ============================================================================
# Finisher - DataHen v3 Boilerplate (e-commerce)
# ============================================================================
#
# PURPOSE: Post-job dedup pass over the `products` collection on the stable id
# (competitor_product_id / _id). Disabled by default in config.yaml — enable
# only when the crawl can emit the same product from multiple listing paths.
#
# DATAHEN v3: TOP-LEVEL SCRIPT. `outputs` is pre-defined.
# find_outputs(collection, query, page, per_page) for cursor pagination.
# ============================================================================

per_page = 500
last_id  = ''
seen     = {}

loop do
  query = { '_id' => { '$gt' => last_id }, '$orderby' => [{ '_id' => 1 }] }
  records = find_outputs('products', query, 1, per_page)
  break if records.nil? || records.empty?

  records.each do |rec|
    last_id = rec['_id']
    key = rec['competitor_product_id'] || rec['_id']
    next if seen[key]
    seen[key] = true

    outputs << rec
    save_outputs(outputs) if outputs.length > 99
  end
end

save_outputs(outputs)
warn "[FINISHER] products deduped → #{seen.size} unique"
