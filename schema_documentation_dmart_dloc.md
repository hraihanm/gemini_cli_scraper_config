# Product Data Schema Specification

## Main Schema Table

| Order | Column Name | Column Type | Description |
|-------|-------------|-------------|-------------|
| 1 | competitor_name | str | Name of company of scraped data |
| 2 | competitor_type | str | dmart, local_store, others<br><br>**Note:** `competitor_type=dmart` static value for every source in dmart project<br><br>"dmart" has to be in all lower case |
| 3 | store_name | str | The store that the product is from. If the competitor offers products from other stores, its name would go here. Otherwise just the competitor's name. For example, an app might have its own stores and then also offer delivery from Edeka. |
| 4 | store_id | str | Competitor store_id if exists |
| 5 | country_iso | str | Country of data scraped, ISO2 format |
| 6 | language | str | Language of data ISO 639-2 |
| 7 | currency_code_lc | str | ISO 4217 of price currency |
| 8 | scraped_at_timestamp | timestamp | Format to follow: scraped_at_timestamp to be YYYY-MM-DD HH:MM:SS date of the data scraping |
| 9 | competitor_product_id | str | Product unique id as per the scraped data source convention (PK of the table) |
| 10 | name | str | Product name |
| 11 | brand | str | Product brand |
| 12 | category_id | str | Category ID |
| 13 | category | str | Product category |
| 14 | sub_category | str | Product sub-category |
| 15 | customer_price_lc | float | Product price shown to the customer (w/ discount applied) |
| 16 | base_price_lc | float | Standard product price (no discount applied) |
| 17 | has_discount | boolean | Is there a discount applied? |
| 18 | discount_percentage | float | Percentage discount on mrp |
| 19 | rank_in_listing | int | Position of the product in the subcategory listing |
| 20 | page_number | int | Page number |
| 21 | product_pieces | int | Number of items in the product package |
| 22 | size_std | float | Unit volume magnitude. Standard. |
| 23 | size_unit_std | str | Unit volume unit. Standard. |
| 24 | description | str | Product description |
| 25 | img_url | str | Main image URL |
| 26 | barcode | int into str | Product barcode |
| 27 | sku | str | Product sku |
| 28 | url | str | The url for the product page |
| 29 | is_available | boolean | Whether the product is available (e.g. in stock) to buy |
| 30 | crawled_source | str | app, website, other -> Should be "WEB" or "APP" |
| 31 | is_promoted | boolean | Any form of promotion eg. banner, swimlane other than strikethrough |
| 32 | type_of_promotion | str | banner, swimlane, top of page, bigger picture, mixmatch, tiered etc. TBD |
| 33 | promo_attributes | struct changed to str | {promo_detail: BOGO/Buy2Get1, free_item:} |
| 34 | is_private_label | boolean | If the product brand is private label or competitor's owned brand |
| 35 | latitude | float | Latitude and Longitude of store (if available). QCommerce is inherently small geographic area speed game eg. Promotion etc are likely to make impact on closer Dmart only. |
| 36 | longitude | float |  |
| 37 | reviews | str | Depending on competitor's review display mechanism we can have {'num_total_reviews':, 'num_avg_reviews':} and so on. |
| 38 | store_reviews | str |  |
| 39 | item_attributes | str | Item's prominent displayed attributes e.g. vegan, bio, eggfree, fairtrade, glutenfree etc. to store competitive differentiator attributes |
| 40 | item_identifiers | str | Items available global/local identifiers based on which it can possibly be matched in future {'barcode': , 'GTIN': } |
| 41 | country_of_origin | str | If applicable, capture the product's country of origin |
| 42 | variants | str | Only applicable in some sources, added as a result of requirement in grabapp sources. Added internally, client spec did not have it or request it |

## Special Field Changes

**Applies to the 5 fields below which were moved from struct to string:**

1. `promo_attributes`
2. `reviews`
3. `store_reviews`
4. `item_attributes`
5. `item_identifiers`

**Special field "variants" only applicable in some sources**

## Eduardo Rosales' Clarification

I just finished reading everything, and also the dhero-dmart channel, including the ndjson schema the client shared to us. We are providing the client a CSV file, but the ndjson schema does provide us with some insights on the fields types and structures they would be expecting.

Let's start with `promo_attributes` field, on the ndjson schema it defines the promo_attributes -> description field as STRING, which rules out a correct approach using an array, which would have look like this on the json:

```json
{"description":["S$5.00 off with S$38.00 min. order", "best buy for $4"],"short tag":""}
```

Notice the `[]` brackets and that each value is enclosed on just double quotes `"`.

So taking an example from the NDJSON file they shared to us, we can see that the promo_attributes -> description field shows as follows:

```json
{"description":"Spend $138, get free New Moon NZ abalone, Spend $138, get $8 off, Buy 1 Scott Extra Toilet Tissue Rolls - Regular (2 Ply) @ $0.90 Off"}
```

Without any `'` in between, but of course that isn't a good idea since it will make it impossible for them to automate the data ingestion correctly, since they won't be able to understand what `,` separate each value and which `,` is just part of the text.

**So a proper approach would be to use `'` to enclose each one, like this:**

```json
{"description":"'Spend $138, get free New Moon NZ abalone', 'Spend $138, get $8 off', 'Buy 1 Scott Extra Toilet Tissue Rolls - Regular (2 Ply) @ $0.90 Off'"}
```

This means that even if it does looks messy when a single item is displayed, for them to avoid special conditions checking if the `'` are present or not before ingesting the data, the correct way to display a single item would be also using the `'`

Like this:

```json
"promo_attributes":{"description":"'Spend $138, get free New Moon NZ abalone'"}
```

**The next factor that matters: the data inside is a string or number value**

- String would need to be in single and then double quotes
- Number will not be in quotes (Eduardo needs to verify)

## Correct Examples

### 1. promo_attributes
To note, a lot of times for promo_attributes we capture from 2 different areas.

```json
{"promo_detail":"'Any 2 @ $9.95'","free_item":""}
{"promo_detail":"'10% off', 'BestSeller'"}
{"description":"'Spend $138, get free New Moon NZ abalone', 'Spend $138, get $8 off', 'Buy 1 Scott Extra Toilet Tissue Rolls - Regular (2 Ply) @ $0.90 Off'"}
```

### 2 & 3. reviews & store_reviews
```json
{"num_total_reviews":113,"avg_rating":4.9}
```

So reviews from source could be either of these 2 options:

1. **No reviews available at all on that full source** - so it would be an empty column with just the header
2. **Reviews available**

For situation #2 where the reviews are available, you will see either of the 3:

1. Reviews information has values -> example: `{"num_total_reviews": 32,"avg_rating":4.2}`
2. Reviews information from site shows null -> then example: `{"num_total_reviews":null,"avg_rating":null}`
3. Review oddly from the site shows 0 or some odd character -> then we capture as is, example: `{"num_total_reviews": -1,"avg_rating":0}`

### 4. item_attributes
To note, a lot of times for item_attributes we capture from 2 different areas, such as tags + dietary attributes for example.

```json
{"dietary attributes":"","tags":"'New'"}
{"dietary attributes":"'Halal','Healthier Choice'","tags":""}
{"cuisine":"'Bakery & Baking Supplies'"}
{"item badge":"'Free_Delivery_7_11', '711_Shop', 'NoCoupon2'"}
```

### 5. item_identifiers
```json
{"barcode":"'8888030066041','8888030300282'"}
{"barcode":"'20916118286'","GTIN":""}
{"barcode":"'8888200708030'"}
```

### Column 42 - variants
This was not in the spec but was introduced to capture the product option modifiers/variants for the Grab App source.

**The rule to follow here is special.** We capture as is for the string values from the app JSON - doesnt follow the pattern for the above fields. For the ones that dont have it, we keep it empty.

## Update 20220224 - Empty Value Handling

When the data does not return any value for these special fields, we will use `""` and not `"''"`

**Examples:**
```json
{"dietary attributes":"","tags":"'New'"}
{"description":""}
```

**CORRECT:** `{"promo_detail":"'Any 2 @ $9.95'","free_item":""}`

**INCORRECT:** `{"promo_detail":"'Any 2 @ $9.95'","free_item":"''"}`

## DLOC Project Schema Extensions

For DLOC projects, the schema follows the same structure as DMART but includes **7 additional fields added at the end**:

### Additional Fields for DLOC Projects

| Order | Column Name | Column Type | Description |
|-------|-------------|-------------|-------------|
| 43 | allergens | str | Product allergens information |
| 44 | nutrition_facts | str | Nutritional information and facts |
| 45 | ingredients | str | Product ingredients list |
| 46 | dimensions | str | Product dimensions (if applicable) |
| 47 | img_url_2 | str | Secondary product image URL |
| 48 | img_url_3 | str | Tertiary product image URL |
| 49 | img_url_4 | str | Quaternary product image URL |

**Note:** These additional fields are specific to DLOC projects and extend the base DMART schema (fields 1-42) with enhanced product information.