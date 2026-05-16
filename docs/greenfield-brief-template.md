# Greenfield Brief Template

Copy this template, fill in your details, and paste it below the `/greenfield-scrape` command.
The agent accepts any of the formats shown — use whichever fits your data.

---

## Minimal template (quick start)

```
/greenfield-scrape url=<TARGET_URL> name=<SCRAPER_SLUG>

Fields:
- <field_name> (<type>): <description>
- <field_name> (<type>): <description>
```

---

## Full template (recommended)

```
/greenfield-scrape url=<TARGET_URL> name=<SCRAPER_SLUG> [auto_next=true]

## Source
- Site name: <e.g. "Example Store">
- Country / Region: <e.g. "UAE" or "Global">
- Start URL: <URL for the first listing, category, or search page>
- Detail URL example: <one sample product/item URL if you have it>

## Crawl Constraints
- Caveats: <known issues — login walls, rate limits, JS-heavy content, etc.>
- Refresh cadence: <daily / weekly / monthly / one-time>
- Dedup key: <field that uniquely identifies a record, e.g. product_id or url>
- Coverage: <all items / only in-stock / only category X>

## Output Fields

| Field name       | Type    | Required | Notes                                  |
|------------------|---------|----------|----------------------------------------|
| <field_name>     | str     | yes      | <what it contains>                     |
| <field_name>     | float   | yes      | <what it contains>                     |
| <field_name>     | int     | no       | may be nil                             |
| <field_name>     | boolean | yes      | true = in stock, false = out of stock  |
| scraped_at       | str     | yes      | ISO timestamp — generated at scrape time |

## Additional Notes
<Any extra context: authentication, regional pricing, consent popups, etc.>
```

---

## Format examples

### Prose (informal)

```
/greenfield-scrape url=https://shop.example.com/products name=example-shop

Scrape all product pages. I need the product title, the current selling price
(as a float), the brand, whether the item is in stock (boolean), and the main
product image URL. Currency is always USD. Skip draft items that have no price.
```

### Bullets

```
/greenfield-scrape url=https://shop.example.com name=example-shop

Output fields:
- product_name (str) — product title, required
- price (float) — selling price, required
- currency (str) — always "USD", hardcoded
- brand (str) — may be nil
- img_url (str) — main product image src
- in_stock (boolean) — true if available
- product_url (str) — canonical detail page URL
- scraped_at (str) — ISO timestamp at scrape time
```

### Markdown table

```
/greenfield-scrape url=https://directory.example.org name=company-directory

| Field            | Type    | Notes                          |
|------------------|---------|--------------------------------|
| company_name     | str     | required                       |
| registration_no  | str     | company registration number    |
| country_code     | str     | ISO 2-char, e.g. SG            |
| industry         | str     | from site taxonomy             |
| founded_year     | int     | may be nil for older entries   |
| website          | str     | may be nil                     |
| scraped_at       | str     | ISO timestamp                  |
```

### Pasted ticket / Jira style

```
/greenfield-scrape url=https://jobs.example.com name=job-board

TICKET: SCRAPE-142
Source: Example Job Board
Country: Singapore
Listings URL: https://jobs.example.com/singapore

Required fields:
  job_title (str), company (str), location (str),
  salary_min (int), salary_max (int),
  posted_date (str), job_url (str)

Optional fields:
  description (str), remote_ok (boolean), skills (str)

Refresh: daily
Dedup key: job_url
Caveats: paginated — detect next-page pattern
```

### With a spec file

If you already have a JSON or CSV spec, pass it with `spec=`:

```
/greenfield-scrape url=https://example.com name=my-scraper spec=my-spec.json
```

CSV format accepted (`column_name`, `column_type`, `dev_notes` columns):

```csv
column_name,column_type,dev_notes
product_name,str,Required - main product title
price,float,Selling price (numeric only, no currency symbol)
currency,str,ISO code e.g. USD - often hardcoded
brand,str,Optional - may be nil
img_url,str,Main product image URL
in_stock,boolean,true = available for purchase
scraped_at,str,ISO timestamp at scrape time
```

---

## Field type reference

| Type | Ruby equivalent | Example values |
|---|---|---|
| `str` | `String` | `"Nike Air Max"`, `"USD"`, `"https://..."` |
| `int` | `Integer` | `42`, `2024` |
| `float` | `Float` | `29.99`, `1499.0` |
| `boolean` | `true` / `false` | `true`, `false` |

Missing / unavailable fields are always `nil` (JSON `null`) — never empty string.

---

## What happens after you submit

1. **Phase 1 (`/greenfield-scrape`)** — Agent reads your brief, builds `field-spec.json`, navigates the site, discovers structure and sample URLs. Outputs `discovery-state.json`.

2. **Phase 2 (`/navigation-parser scraper=<name> project=greenfield`)** — Agent generates `categories.rb` / `listings.rb` to enumerate all detail URLs.

3. **Phase 3 (`/details-parser scraper=<name> project=greenfield`)** — Agent discovers CSS selectors (or JSON-LD) for each field and generates `details.rb`.

All generated files land in `generated_scraper/<name>/`.
