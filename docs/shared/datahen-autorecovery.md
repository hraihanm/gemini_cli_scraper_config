# DataHen V3 — Autorecovery Standard

Every parser must handle fetch failures. This document is the single source of truth
for the recovery pattern used in this project's boilerplates.

---

## The three recovery actions

| Action | DataHen call | When to use |
|---|---|---|
| **Retry** | `refetch page['gid']` | Transient error — network, 5xx, timeout |
| **Give up** | `limbo page['gid']` | Permanent error — threshold exceeded, 404, auth exhausted |
| **Ignore** | `finish` | Out-of-scope page, handled and written to side collection |

**`finish` is always required after `limbo` or `refetch`.** Without it the parser continues
executing on the failed/empty content, producing garbage output.

---

## Standard function — `autorecovery`

Put this in `lib/helpers.rb` and `require './lib/helpers'` in every parser.

```ruby
# lib/helpers.rb

# Standard fetch-error recovery.
# Routes by status code; retries up to MAX_REFETCH attempts then limbo.
MAX_REFETCH = 3

def autorecovery(reason: nil, status: nil)
  status ||= page['failed_response_status_code']
  msg = [reason, status && "HTTP #{status}"].compact.join(' | ')
  puts "RECOVERY: #{msg}" if ENV['debug']

  case status
  when 404
    # Not found — no point retrying; send straight to limbo
    limbo page['gid']
  when 403, 429
    # Auth or rate-limit — always retry; do not count against refetch threshold
    refetch page['gid']
  else
    # Transient or unknown — retry up to MAX_REFETCH, then limbo
    if page['refetch_count'].to_i >= MAX_REFETCH
      limbo page['gid']
    else
      refetch page['gid']
    end
  end

  finish  # always — stops parser execution after recovery action
end

# Backward-compat alias used in older scrapers
def autorefetch(reason = nil)
  autorecovery(reason: reason)
end

# Explicit limbo without retry — for permanent failures or out-of-scope pages
def autolimbo(reason = nil)
  puts "LIMBO: #{reason}" if ENV['debug']
  limbo page['gid']
  finish
end
```

---

## Standard top-of-parser response guard

Copy this block verbatim at the top of every parser, **before** any parsing logic:

```ruby
require './lib/helpers'

# ── Response guard ──────────────────────────────────────────────────────────
if page['failed_response_status_code']
  autorecovery(status: page['failed_response_status_code'],
               reason: "fetch failed on #{page['url']}")
end
raise "unexpected status #{page['response_status_code']}" \
  unless page['response_status_code'].nil? || page['response_status_code'] == 200
# ────────────────────────────────────────────────────────────────────────────
```

The `raise` on unexpected non-200 lets DataHen mark the page as failed and surface it
in dashboards — preferable to silently continuing on a broken response.

---

## Threshold reference

| Context | `MAX_REFETCH` | Rationale |
|---|---|---|
| Standard (retail, food) | **3** (4 total attempts) | Production standard — parknshop, naivas_ke, coupang |
| Strict (expensive API calls) | **1** (2 total attempts) | Fail fast; manual review via limbo |
| High-flakiness sites | **5** | Cloudflare / rate-limited sites only |

Set `MAX_REFETCH` as a constant in `lib/helpers.rb`; override in parser if site warrants it.

---

## Status-code routing decisions

| Status | Action | Why |
|---|---|---|
| 200 | Continue parsing | Success |
| 301 / 302 | Transparent — DataHen follows | `page['effective_url']` has final URL |
| 403 | `refetch` (always) | Session / auth expired — worth retrying |
| 404 | `limbo` (immediately) | Page removed — retry wastes quota |
| 429 | `refetch` (always) | Rate-limited — retry after back-off |
| 500 / 503 | Threshold retry → limbo | Server error — may be transient |
| nil (failed_response_status_code set) | `autorecovery` default | DataHen returned a failure |

---

## Pattern variants seen in production

| Variant | Where | Use |
|---|---|---|
| `autorecovery` (this doc) | boilerplate standard | All new scrapers |
| Inline `if refetch_count > N … limbo … refetch … finish` | legacy scrapers | Don't change unless rewriting |
| `autolimbo` only (no retry) | yandex_am/kg, talabatey, monchis | When operator wants manual review over retry |
| `raise "Fail!"` on exhaustion | yelp-scraper | Hard-fail for dashboard visibility |
| Per-status-code routing (snoonu_qa) | advanced | Refined version of this standard |
| Vars-carried counter | noon | When driver rename resets DataHen's native count |
| Cloudflare loop (`dh_cloudscraper.rb`) | drmax_cz, lemonpharmacy, lider | Multi-page-type Cloudflare bypass — out of scope here |

---

## What NOT to do

```ruby
# ❌ Missing finish — parser continues on failed content
if page['refetch_count'] > 3
  limbo page['gid']
end
refetch page['gid']
# parser keeps running here

# ❌ No recovery at all — silent nil output on network failures
html = Nokogiri::HTML(content)
outputs << { name: html.at_css('.title')&.text }  # nil if page was empty

# ❌ rescue nil on full parser — swallows all errors
begin
  # ... all parsing logic
rescue
  nil  # errors disappear silently
end
```

---

## DNA / GSG / other families

- **dna** (elisa, gigantti, power, telia, verkkokauppa, veikonkone) — retail, same recovery pattern as dmart
- **gsg** (savoo_co_uk) — coupon/voucher; exports `coupons` + `api_upload_failure`; uses standard threshold-based refetch
- **oiva_fi** — restaurant hygiene registry; `locations` only, no `items`; uses status-code guard
- **yellowpages_egypt**, **yelp-scraper** — business directories; use `raise` on exhaustion
- **bolagskervet** — government registry (deferred)
- **aviv** — deferred
