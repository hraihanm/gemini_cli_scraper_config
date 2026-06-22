# DHero Seeding Strategies

**Used by:** dhero Phase 1 (STEP 8b) + the boilerplate `seeder/seeder.rb`.

Most dhero sources are **API-driven**: the restaurant list is fetched from a JSON endpoint keyed by geography or session, not crawled from an HTML listing page. Pick one strategy during discovery, record it in `discovery-state.json.seeding.strategy`, and uncomment the matching block in the seeder.

| Strategy | Source pattern | Reference scraper |
|---|---|---|
| `geo_grid` | listing endpoint takes `lat`/`long` | totersapp, mrsool |
| `h3_hexagon` | listing endpoint takes an H3 cell id | lezzoo |
| `city_list` / `neighborhood_list` | listing endpoint takes a city/zone id | talabatey, jahez |
| `url_listings` | paginated HTML restaurant list | openrice |
| `session_bootstrap` | must mint a token / set location before listing | monchis |

In every case the downstream contract is the same: a `listings`/`menu` parser emits the canonical `locations` + `items` records (see `docs/shared/dhero-output-schema.md`). Only the *entry* differs.

---

## geo_grid
Coordinates drive coverage. Maintain `input/geo.csv` (`city,lat,long`); seed one listings request per row and carry the coordinates forward so the restaurant record can populate `input_lat`/`input_long`.

```ruby
require 'csv'
CSV.foreach('./input/geo.csv', headers: true) do |row|
  pages << Helpers.listings_page(page_number: 1, vars: {
    'city' => row['city'], 'input_lat' => row['lat'].to_f, 'input_long' => row['long'].to_f
  })
end
```
Pagination: usually `page_number` or `offset` per point. Dedup restaurants across overlapping points in the listings parser (`seen_ids`).

## h3_hexagon
The app resolves a city to an H3 cell; the listing endpoint takes the cell id. Seed a city→hex map. An `init`/widgets page often fans out into several `listings` requests (open + closed, offsets, widget ids) — mirror lezzoo's `init.rb`.

```ruby
CITY_HEX.each do |city, hex|
  pages << { url: "#{base}/widgets/page?city=#{city}&hexagonId=#{hex}", page_type: 'init',
             vars: { 'city' => city, 'hexagonId' => hex } }
end
```

## city_list / neighborhood_list
Iterate a list of city/neighborhood/zone ids; one listings request each (POST body or query param). Pull the id list from an index endpoint when one exists (talabatey `Neighborhoods`), else hardcode it from discovery.

## url_listings (HTML)
A genuine website with a paginated restaurant list. Seed the listings URL, paginate via count or next-button (see `listings.rb` Strategy 1/2). This is the `kind=html` path — the only dhero shape that matches the legacy HTML pipeline.

## session_bootstrap
The listing endpoint 401s without a token and/or a set delivery location. Seed a `bootstrap` page that:
1. mints a token (e.g. guest `make_user`), then
2. POSTs a default address / set-location, then
3. queues the `listings` page(s) with the token header attached (carry it in `vars` and merge into `headers`).

Capture which header the token belongs in during STEP 7b. Keep the token on every downstream request.

---

## Pagination cheat-sheet
- `page_number` — increment until `current_page == last_page` (snoonu, totersapp).
- `offset` — step by page size until an empty `data` array (lezzoo merchant-list).
- `cursor` — follow `pageInfo.endCursor` while `hasNextPage` (GraphQL).
- `hexagon_fanout` — fixed set of cells/widgets/offsets, no terminal condition (lezzoo init).
- `next_button` — follow the next link until absent (HTML).
