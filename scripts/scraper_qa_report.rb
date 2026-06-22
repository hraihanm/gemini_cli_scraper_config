#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================================================
# scraper_qa_report.rb — one-shot QA + deploy-readiness report (all projects)
# ============================================================================
#
# Project-agnostic: works for dhero (locations/items), dmart-dloc and greenfield
# (single `products` collection), or any spec. Consumes sample output records
# collected during generation + the field spec, then emits into the scraper dir:
#
#   spec.csv               field-availability matrix (Yes/Partial/No + nil%)
#   GENERATION_REPORT.md   build summary, nil-rate, samples, id integrity,
#                          decision trail, deploy commands
#   deploy-readiness.json  machine gates → { ..., "deployable": true|false }
#   DATAHEN_PROJECT.txt    filled from discovery-state (only if absent)
#
# Usage:
#   ruby scripts/scraper_qa_report.rb <scraper_dir> [--project <name>] \
#        [--spec <field-spec.json>] [--eval-score N] [--name <scraper_name>]
#
# Collections are derived from the sample files present:
#   <scraper_dir>/.scraper-state/qa-samples/<collection>.json   (array of records)
#   — or a single qa-samples/outputs.json (mixed, split by _collection)
# Spec fields map to a collection by their `collection` key; specs without that
# key (dmart/greenfield) treat ALL fields as the single sampled collection.
#
# Pure stdlib; never raises on missing samples — emits a partial report instead.
# ============================================================================

require 'json'
require 'csv'
require 'time'
require 'fileutils'
require 'open3'

YES_MAX_NIL       = 0.25   # < 25% nil → "Yes"; 25..<100% → "Partial"; 100% → "No"
REQUIRED_PRIORITY = 1      # priority-1 fields must be non-nil on every sample
MIN_SAMPLES       = 3      # need ≥3 records per collection for a real verdict

# ---------------------------------------------------------------------------
def parse_args(argv)
  opts = { spec: nil, eval_score: nil, name: nil, project: nil,
           require_eval: false, model: nil, agy_version: nil, telemetry: nil }
  dir = nil
  i = 0
  while i < argv.length
    case argv[i]
    when '--spec'         then opts[:spec] = argv[i += 1]
    when '--eval-score'   then opts[:eval_score] = argv[i += 1]&.to_f
    when '--name'         then opts[:name] = argv[i += 1]
    when '--project'      then opts[:project] = argv[i += 1]
    when '--require-eval' then opts[:require_eval] = true
    when '--model'        then opts[:model] = argv[i += 1]
    when '--agy-version'  then opts[:agy_version] = argv[i += 1]
    when '--telemetry'    then opts[:telemetry] = argv[i += 1]
    else dir ||= argv[i]
    end
    i += 1
  end
  [dir, opts]
end

# Resolve version-pinning metadata for reproducibility.
# Open3 (no shell) → cross-platform; avoids cmd.exe `2>/dev/null` breakage on Windows.
def git_commit(dir)
  out, status = Open3.capture2('git', '-C', dir, 'rev-parse', '--short', 'HEAD')
  status.success? ? out.strip : nil
rescue StandardError
  nil
end

def version_meta(spec, scraper_dir, opts)
  commit = git_commit(scraper_dir) || git_commit(File.dirname(__FILE__))
  {
    'field_spec_version' => (spec['version'] rescue nil),
    'git_commit' => (commit && !commit.empty? ? commit : nil),
    'model' => opts[:model],
    'agy_version' => opts[:agy_version]
  }
end

def load_json(path)
  return nil unless path && File.exist?(path)
  JSON.parse(File.read(path))
rescue JSON::ParserError => e
  warn "⚠ could not parse #{path}: #{e.message}"
  nil
end

def blank?(v)
  v.nil? ||
    (v.is_a?(String) && v.strip.empty?) ||
    (v.is_a?(Array) && v.empty?) ||
    (v.is_a?(Hash) && v.empty?)
end

def type_ok?(value, type)
  return true if value.nil?
  case type
  when 'str', 'timestamp' then value.is_a?(String)
  when 'float'            then value.is_a?(Numeric)
  when 'int'             then value.is_a?(Integer) || (value.is_a?(Float) && value == value.to_i)
  when 'boolean'         then value == true || value == false
  when 'hash'            then value.is_a?(Hash)
  when 'array'           then value.is_a?(Array)
  else true
  end
end

def fetch(rec, key)
  rec.key?(key) ? rec[key] : rec[key.to_sym]
end

def rec_id(r)
  r['_id'] || r[:_id] || r['lead_id'] || r['item_id'] || r['competitor_product_id'] ||
    r[:lead_id] || r[:item_id] || r[:competitor_product_id]
end

# ---------------------------------------------------------------------------
def locate_spec(explicit, scraper_dir)
  [
    explicit,
    File.join(scraper_dir, '.scraper-state', 'field-spec.json'),
    File.join(File.dirname(__FILE__), '..', 'field-spec.json'),
    File.join(File.dirname(__FILE__), '..', 'dhero-field-spec.json')
  ].compact.find { |p| File.exist?(p) }
end

# Load samples as { collection_name => [records] } from qa-samples/*.json.
def load_samples(scraper_dir)
  qa = File.join(scraper_dir, '.scraper-state', 'qa-samples')
  samples = {}
  Dir.glob(File.join(qa, '*.json').gsub('\\', '/')).each do |f|
    name = File.basename(f, '.json')
    next if name == 'outputs'
    data = load_json(f)
    samples[name] = Array(data) if data
  end
  # fallback: a single mixed outputs.json split by _collection
  if samples.empty?
    mixed = load_json(File.join(qa, 'outputs.json'))
    Array(mixed).each do |rec|
      col = rec['_collection'] || rec[:_collection] || 'products'
      (samples[col] ||= []) << rec
    end if mixed
  end
  samples
end

# Decide which spec fields belong to a sampled collection.
# - spec has per-field `collection` key → match it.
# - spec has no `collection` key anywhere (dmart/greenfield) → all fields.
def fields_for(collection, all_fields, spec_has_collection)
  spec_has_collection ? all_fields.select { |f| f['collection'] == collection } : all_fields
end

# ---------------------------------------------------------------------------
def analyze(spec_fields, records, collection)
  records = Array(records)
  n = records.length
  spec_fields.map do |f|
    name = f['name']
    present = 0
    nonblank = 0
    type_bad = 0
    records.each do |rec|
      present += 1 if rec.key?(name) || rec.key?(name.to_sym)
      val = fetch(rec, name)
      nonblank += 1 unless blank?(val)
      type_bad += 1 unless type_ok?(val, f['type'])
    end
    nil_rate = n.zero? ? nil : (n - nonblank).to_f / n
    availability =
      if n.zero?               then 'Unknown'
      elsif nonblank.zero?     then 'No'
      elsif nil_rate < YES_MAX_NIL then 'Yes'
      else 'Partial'
      end
    {
      name: name, collection: collection, type: f['type'], priority: f['priority'],
      output_file: Array(f['output_file']).join('+'), extraction_method: f['extraction_method'],
      present_count: present, nonblank_count: nonblank, sample_count: n,
      nil_rate: nil_rate, availability: availability, type_violations: type_bad,
      missing_key: present < n, notes: (f['notes'] || '').gsub(/\s+/, ' ').strip
    }
  end
end

def id_integrity(samples)
  out = {}
  samples.each do |col, recs|
    next if recs.empty?
    ids = recs.map { |r| rec_id(r) }.compact
    out["#{col}_id_present"] = ids.length == recs.length
    out["#{col}_id_unique"]  = ids.uniq.length == ids.length
  end
  # dhero-style cross-collection linkage when both sides were sampled
  loc = samples['locations']
  items = samples['items']
  if loc && !loc.empty? && items && !items.empty?
    loc_ids = loc.map { |r| fetch(r, 'lead_id') }.compact.uniq
    item_lead = items.map { |r| fetch(r, 'lead_id') }.compact.uniq
    out['item_lead_in_locations'] = (loc_ids.empty? || item_lead.empty?) ? nil : (item_lead - loc_ids).empty?
  end
  out
end

def collect_decision_log(scraper_dir)
  log = []
  Dir.glob(File.join(scraper_dir, '.scraper-state', '*-state.json').gsub('\\', '/')).sort.each do |path|
    data = load_json(path)
    next unless data.is_a?(Hash) && data['_log'].is_a?(Array)
    src = File.basename(path)
    data['_log'].each { |e| log << e.merge('_source' => src) }
  end
  log
end

# ---------------------------------------------------------------------------
def compute_gates(rows, ids, eval_score, sample_counts, require_eval = false)
  active = rows.reject { |r| r[:sample_count].zero? }

  missing_keys = active.select { |r| r[:missing_key] }
  schema_ok = missing_keys.empty?

  type_bad = active.select { |r| r[:type_violations] > 0 }
  types_ok = type_bad.empty?

  required = active.select { |r| r[:priority] == REQUIRED_PRIORITY }
  required_bad = required.select { |r| r[:nonblank_count] < r[:sample_count] }
  required_fields_ok = required.any? ? required_bad.empty? : nil

  important = active.select { |r| r[:priority] && r[:priority] <= 2 }
  important_empty = important.select { |r| r[:availability] == 'No' }
  nil_rate_ok = important.any? ? important_empty.empty? : nil

  id_checks = ids.values.compact
  ids_ok = id_checks.empty? ? nil : id_checks.all?

  # eval gate: with --require-eval, a missing score is a BLOCKING failure
  # (no vacuous pass); otherwise it is informational (nil = n/a).
  eval_ok = if !eval_score.nil? then eval_score >= 80.0
            elsif require_eval  then false
            else nil
            end
  eval_missing = require_eval && eval_score.nil?

  # every sampled collection must clear MIN_SAMPLES, else gates pass vacuously
  sample_blockers = sample_counts.reject { |_, c| c >= MIN_SAMPLES }
                                 .map { |col, c| "#{col}=#{c} (<#{MIN_SAMPLES})" }
  samples_ok = !sample_counts.empty? && sample_counts.values.all? { |c| c >= MIN_SAMPLES }

  hard = [samples_ok, schema_ok, types_ok, required_fields_ok, ids_ok].compact
  deployable = samples_ok && !hard.empty? && hard.all? && (eval_ok != false)

  {
    'samples_ok' => samples_ok,
    'schema_ok' => schema_ok,
    'types_ok' => types_ok,
    'required_fields_ok' => required_fields_ok,
    'ids_ok' => ids_ok,
    'eval_ok' => eval_ok,
    'nil_rate_ok' => nil_rate_ok,
    'deployable' => deployable,
    '_blocking' => {
      'insufficient_samples' => sample_blockers,
      'evals_required' => (eval_missing ? ['no eval fixture/score — run scraper_run_evals (gate is mandatory)'] : []),
      'missing_keys' => missing_keys.map { |r| "#{r[:collection]}.#{r[:name]}" },
      'type_violations' => type_bad.map { |r| "#{r[:collection]}.#{r[:name]}" },
      'required_nil' => required_bad.map { |r| "#{r[:collection]}.#{r[:name]}" },
      'id_failures' => ids.select { |_, v| v == false }.keys.map(&:to_s)
    },
    '_warnings' => {
      'priority2_all_nil' => important_empty.map { |r| "#{r[:collection]}.#{r[:name]}" }
    }
  }
end

# ---------------------------------------------------------------------------
def pct(rate)
  rate.nil? ? 'n/a' : "#{(rate * 100).round(1)}%"
end

def write_spec_csv(path, rows)
  CSV.open(path, 'w') do |csv|
    csv << ['#', 'Field', 'Collection', 'Available?', 'Nil%', 'Type', 'Priority', 'Export', 'Notes']
    rows.each_with_index do |r, i|
      avail = r[:missing_key] ? "#{r[:availability]} (KEY MISSING)" : r[:availability]
      csv << [i + 1, r[:name], r[:collection], avail, pct(r[:nil_rate]),
              r[:type], r[:priority], r[:output_file], r[:notes]]
    end
  end
end

def write_deploy_readiness(path, gates, meta)
  File.write(path, JSON.pretty_generate(gates.merge('_meta' => meta)) + "\n")
end

def write_datahen_project(path, discovery, name, project, collections)
  return if File.exist?(path)
  dht = project || 'dhero'
  lines = ["dht_type=#{dht}", "scraper_name=#{name}"]
  if discovery.is_a?(Hash)
    country = discovery['country_iso'] || discovery['country']
    lines << 'input_vars=country' unless country.to_s.empty?
  end
  lines << "page_types=#{collections.join(',')}" unless collections.empty?
  File.write(path, lines.join("\n") + "\n")
end

def avail_summary(rows)
  rows.group_by { |r| r[:availability] }.transform_values(&:count)
end

def write_report(path, ctx)
  rows = ctx[:rows]; gates = ctx[:gates]; ids = ctx[:ids]; log = ctx[:log]
  samples = ctx[:samples]; name = ctx[:name]; eval_score = ctx[:eval_score]
  project = ctx[:project]; collections = ctx[:collections]
  versions = ctx[:versions] || {}; telemetry = ctx[:telemetry]
  badge = gates['deployable'] ? '✅ DEPLOYABLE' : '⛔ NOT DEPLOYABLE'

  vstr = versions.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v}" }.join(' · ')

  io = +""
  io << "# Generation Report — #{name}\n\n"
  io << "**Generated:** #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}  \n"
  io << "**Project:** #{project || 'unknown'}  \n"
  io << "**Collections:** #{collections.join(', ')}  \n"
  io << "**Versions:** #{vstr.empty? ? 'n/a' : vstr}  \n"
  io << "**Deploy gate:** #{badge}\n\n"

  io << "## Deploy-readiness gates\n\n| Gate | Result |\n|---|---|\n"
  %w[samples_ok schema_ok types_ok required_fields_ok ids_ok eval_ok deployable].each do |g|
    v = gates[g]
    mark = v == true ? '✅ pass' : v == false ? '❌ FAIL' : '— n/a'
    io << "| `#{g}` | #{mark} |\n"
  end
  io << "\n"
  blocking = gates['_blocking'].reject { |_, v| v.empty? }
  unless blocking.empty?
    io << "**Blocking issues (must fix before deploy):**\n\n"
    blocking.each { |k, v| io << "- `#{k}`: #{v.join(', ')}\n" }
    io << "\n"
  end
  warnings = (gates['_warnings'] || {}).reject { |_, v| v.empty? }
  unless warnings.empty?
    io << "**Warnings (non-blocking — confirm genuine data gaps):**\n\n"
    warnings.each { |k, v| io << "- `#{k}`: #{v.join(', ')}\n" }
    io << "\n"
  end

  io << "## Sample coverage\n\n"
  collections.each { |c| io << "- #{c} sampled: **#{samples[c]&.length || 0}**\n" }
  io << "- eval score: **#{eval_score ? "#{eval_score}%" : 'not run'}**\n"
  if telemetry.is_a?(Hash) && !telemetry.empty?
    io << "- telemetry: #{telemetry.map { |k, v| "#{k}=#{v}" }.join(' · ')}\n"
  end
  io << "\n"

  collections.each do |col|
    crows = rows.select { |r| r[:collection] == col }
    next if crows.empty?
    sm = avail_summary(crows)
    io << "## #{col} field availability  "
    io << "(Yes: #{sm['Yes'] || 0} · Partial: #{sm['Partial'] || 0} · No: #{sm['No'] || 0} · Unknown: #{sm['Unknown'] || 0})\n\n"
    io << "| Field | Avail | Nil% | Type | Pri | Export |\n|---|---|---|---|---|---|\n"
    crows.each do |r|
      avail = r[:missing_key] ? "#{r[:availability]} ⚠KEY" : r[:availability]
      io << "| `#{r[:name]}` | #{avail} | #{pct(r[:nil_rate])} | #{r[:type]} | #{r[:priority]} | #{r[:output_file]} |\n"
    end
    io << "\n"
  end

  io << "## ID integrity\n\n| Check | Result |\n|---|---|\n"
  ids.each do |k, v|
    mark = v == true ? '✅' : v == false ? '❌' : '—'
    io << "| #{k} | #{mark} |\n"
  end
  io << "\n"

  io << "## Sample records\n\n"
  collections.each do |col|
    rec = samples[col]&.first
    next unless rec
    io << "**#{col}[0]:**\n\n```json\n#{JSON.pretty_generate(rec)}\n```\n\n"
  end

  io << "## Decision trail (`_log`)\n\n"
  if log.empty?
    io << "_No `_log` entries found in state files._\n\n"
  else
    io << "| Source | Step | Action | Detail |\n|---|---|---|---|\n"
    log.each do |e|
      detail = e.reject { |k, _| %w[_source step action].include?(k) }
                .map { |k, v| "#{k}=#{v}" }.join(' ')
      io << "| #{e['_source']} | #{e['step']} | #{e['action']} | #{detail.gsub('|', '\\|')} |\n"
    end
    io << "\n"
  end

  io << "## Deploy sequence\n\n"
  if gates['deployable']
    io << "```bash\nhen scraper deploy #{name}\nhen scraper show #{name}   # verify deployed_commit_hash\n```\n"
  else
    io << "Resolve the blocking issues above, re-run `/qa scraper=#{name}#{project ? " project=#{project}" : ''}`, then deploy.\n"
  end

  File.write(path, io)
end

# ---------------------------------------------------------------------------
def main
  scraper_dir, opts = parse_args(ARGV)
  unless scraper_dir && Dir.exist?(scraper_dir)
    puts 'Usage: ruby scraper_qa_report.rb <scraper_dir> [--project <name>] [--spec <path>] [--eval-score N] [--name <name>]'
    exit 1
  end
  scraper_dir = File.expand_path(scraper_dir)
  name = opts[:name] || File.basename(scraper_dir)

  spec = load_json(locate_spec(opts[:spec], scraper_dir))
  unless spec && spec['fields']
    puts '✗ No usable field spec found (.scraper-state/field-spec.json / field-spec.json). Aborting.'
    exit 1
  end
  all_fields = spec['fields']
  spec_has_collection = all_fields.any? { |f| f.key?('collection') }

  samples = load_samples(scraper_dir)
  warn "⚠ No QA samples in #{scraper_dir}/.scraper-state/qa-samples/ — report will be schema-only." if samples.empty?

  # collections: those sampled; if none sampled, fall back to spec collections (or 'products')
  collections =
    if !samples.empty? then samples.keys.sort
    elsif spec_has_collection then all_fields.map { |f| f['collection'] }.compact.uniq.sort
    else ['products']
    end

  rows = collections.flat_map do |col|
    analyze(fields_for(col, all_fields, spec_has_collection), samples[col] || [], col)
  end

  ids = id_integrity(samples)
  log = collect_decision_log(scraper_dir)
  sample_counts = collections.each_with_object({}) { |c, h| h[c] = (samples[c] || []).length }
  gates = compute_gates(rows, ids, opts[:eval_score], sample_counts, opts[:require_eval])

  discovery = load_json(File.join(scraper_dir, '.scraper-state', 'discovery-state.json'))

  telemetry = (JSON.parse(opts[:telemetry]) rescue nil) if opts[:telemetry]

  meta = {
    'scraper' => name, 'project' => opts[:project],
    'generated_at' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
    'sample_counts' => sample_counts, 'eval_score' => opts[:eval_score],
    'require_eval' => opts[:require_eval],
    'versions' => version_meta(spec, scraper_dir, opts),
    'telemetry' => telemetry   # {tool_calls, elapsed_s, est_cost_usd, ...} from the skill
  }

  spec_csv   = File.join(scraper_dir, 'spec.csv')
  report_md  = File.join(scraper_dir, 'GENERATION_REPORT.md')
  readiness  = File.join(scraper_dir, 'deploy-readiness.json')
  project_txt = File.join(scraper_dir, 'DATAHEN_PROJECT.txt')

  write_spec_csv(spec_csv, rows)
  write_deploy_readiness(readiness, gates, meta)
  write_report(report_md, name: name, rows: rows, gates: gates, ids: ids, log: log,
                          samples: samples, eval_score: opts[:eval_score],
                          project: opts[:project], collections: collections,
                          versions: meta['versions'], telemetry: telemetry)
  write_datahen_project(project_txt, discovery, name, opts[:project], collections)

  puts "=== QA report — #{name} (#{opts[:project] || 'project?'}) ==="
  puts "  spec.csv             → #{spec_csv}"
  puts "  GENERATION_REPORT.md → #{report_md}"
  puts "  deploy-readiness.json→ #{readiness}"
  puts "  DATAHEN_PROJECT.txt  → #{project_txt} (#{File.exist?(project_txt) ? 'written/exists' : 'skipped'})"
  puts ''
  puts gates['deployable'] ? '✅ DEPLOYABLE' : '⛔ NOT DEPLOYABLE'
  gates['_blocking'].reject { |_, v| v.empty? }.each { |k, v| puts "   - #{k}: #{v.join(', ')}" }
  exit(gates['deployable'] ? 0 : 2)
end

main if $PROGRAM_NAME == __FILE__
