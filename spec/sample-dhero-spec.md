**Fields from HERO DOCUMENTATION - Output Requirements (3 Files)**

**Filled out by Jose, then updated by Riyan**

|  | **JSON field** | **Explanation** | **Format** | **QA check** | **Retrieved From CI** | **Retrieved From BO** |
| --- | --- | --- | --- | --- | --- | --- |
| A1.1 | date | Date of scraping | String (YYYYMMDD) | Should be “date":"YYYYMMDD HH:MM:SS" ("date":"20191129 14:52:43") | fetched_at from scraper |  |
| A1.2 | lead_id | Unique lead identifier | UUID v4 | Should not repeat Should match the lead_id in A1 file More detailed check in QA Process “ **Lead ID Continuity Check”** | id |  |
| A1.3 | url | Url from which restaurant info scraped | string | Present in website sources Should be null when the source is an APP | - |  |
| A1.4 | restaurant_name | Name of restaurant | string | Should never be blank | name |  |
| A1.5 | restaurant_address | Scraped address information | string | Should have a restaurant address If missing, validate against source - if the source does not have it, it should be null | address > short |  |
| A1.6 | restaurant_post_code | Zip code of restaurant location | string | Should have a postal code /zip code If missing, validate against source - if the source does not have it, it should be null | - |  |
| A1.7 | restaurant_area | Area name of restaurant location | string | Should have a restaurant area If missing, validate against source - if the source does not have it, it should be null restaurant_area is the region | - |  |
| A1.8 | Restaurant_coordinates (2 fields) | Latitude, longitude | float | Should have 2 columns: a latitude ("restaurant_lat") and a longitude ("restaurant_long"). If missing, validate against source - if the source does not have it, it should be null | address > location > latitude/longitude |  |
| A1.9 | restaurant_city | City name of restaurant location | string | Should have the city of the restaurant If missing, validate against website - if the website does not have it, it should be null | address > city |  |
| A1.10 | restaurant_country | Country name of restaurant location |  |  | Hardcoded CI |  |
| A1.11 | restaurant_delivers | Boolean for if the restaurant delivers | boolean | **restaurant_delivers":false** | delivery |  |
| A1.12 | phone_number | Contact phone number of the restaurant including country code | string | Should have a phone number If missing, validate against source - if the source does not have it, it should be null | - |  |
| A1.13 | restaurant_rating | User rating of restaurant however it is visualized by the website (e.g. 4.5 stars or 90% satisfaction) if multiple ratings are available pls send in json format as example | string, however visualized by website (e.g. 4.5 stars or, 90%) or ratings in json format, if multiple restaurant rating (service, food_quality) | Should have the rating of the restaurant If missing, validate against the source - if the source does not have it, it should be null. If there is more than one rating, restaurant_rating should have the value of the most general rating for the restaurant. | rating |  |
| A1.14 | restaurant_position | Position the restaurant was in the listing | integer, e.g.: 1, 2, 3, 4, 5 | Restaurant_Position can be empty when not available in the source | based on restaurant position, count it with scraper |  |
| A1.15 | number_of_ratings | Number of user ratings | integer | It is usually displayed next to rating If missing, validate against the source - if the source does not have it, it should be null. | ratingCount |  |
| A1.16 | main_cuisine | Main_cuisine is displayed under the restaurant information. Example “ Italian” , “ Vegan” etc | string | **one cuisine** | tags get the first one |  |
| A1.17 | is_permanently_closed (added ~May 2023) | Whether the restaurant is permanently closed | boolean | `false` for all available restaurants. `null` if no suitable selector exists. Client does not want permanently closed locations in output. | HARDCODED false |  |
| A1.18 | input_lat + input_long (added Aug 2023) | Latitude, longitude from the input list | float | Only applicable for geo-coordinate search scrapers. Confirm during feasibility check. `null` if not applicable. | page['vars']['input_lat'] / page['vars']['input_long'] |  |

**A2: File structure format:: JSON :: RESTAURANT - VARIABLE FIELDS (standardized naming)**

Note: `opening_hours`, `restaurant_tags`, and `restaurant_delivery_zones` appear in **both A1 and A2**.

|  | **JSON field** | **Explanation** | **Format** | **QA Check** | **Retrieved From CI** | **Retrieved From BO** |
| --- | --- | --- | --- | --- | --- | --- |
| A2.1 | date | Date of scraping | String (YYYYMMDD) | Should be “date”:”YYYYMMDD HH:MM:SS” (“date”:”20191129 14:52:43”) | fetched_at from scraper |  |
| A2.2 | lead_id | Unique lead identifier | UUID v4 | Should not repeat Should match the lead_id in A1 file More detailed check in QA Process “ **Lead ID Continuity Check”** | id |  |
| A2.3 | url | Url from which restaurant info scraped | string | Present in website sources Should be null when the source is an APP | - |  |
| A2.4 | cuisine_name | Json format, ordered as visible on website. Keys: cuisine1, cuisine2, ... | e.g. { “cuisine1”: “pizza”, “cuisine2”: “burger” } | All cuisines captured. **”cuisine_name”:{}** if none found | tags |  |
| A2.5 | opening_hours *(also in A1)* | JSON data containing a key per day of the week with a list of string values consisting of 24h open-close pairs Days on which restaurant is closed should be omitted | .{ “Sun”: [“1000-2200”], “Mon”: [“0800-1130”, “1600-2330”] } | **”opening_hours”:null** Example: “opening_hours”:{“Tue”:[“1100-1700”],”Wed”:[“1100-1700”],”Thu”:[“1100-1700”],”Fri”:[“1100-1700”]} | footerDescription get business hour from text with regex |  |
| A2.6 | restaurant_tags *(also in A1)* | list of tags associated with the restaurant No standardized names, different per website | Array | **”restaurant_tags”:null** Example: “restaurant_tags”:[“Burger”, “Online payment”] | - |  |
| A2.7 | restaurant_delivery_zones *(also in A1)* | Delivery zones associated with restaurants. Standardized names must include: delivery_zone, minimum_order_value, delivery_fee, currency (ISO 4217) | Hash | **”restaurant_delivery_zones”:null** Example: “restaurant_delivery_zones”:[{“delivery_zone”:”Sanidego”,”minimum_order_value”:0.0,”delivery_fee”:null,”currency”:”IQD”}] | - |  |
| A2.8 | free_field |  | Hash | **”free_field”:null** **null** . | - |  |

**A3: File structure format:: JSON :: menu ITEM LEVEL (dish) - VARIABLE FIELDS (standardized naming) **

|  | **JSON field** | **Explanation** | **Format** | **QA Check** | **Retrieved From CI** | **Retrieved From BO** |
| --- | --- | --- | --- | --- | --- | --- |
| A3.1 | date | Date of scraping | String (YYYYMMDD) | Should be “date":"YYYYMMDD HH:MM:SS" ("date":"20191129 14:52:43") | fetched_at from scraper |  |
| A3.2 | lead_id | Unique lead identifier | UUID v4 | Normal to have repeats The Lead_id here is based on the restaurant lead id in A1 and A2 file. So if a restaurant has 100 items then there will be 100 item records with the same lead_id as the restaurant lead id. Example: A1 file - Restaurant_name has 3 items and lead_id *9645813016256c1a1df46583e32a8a15* A3 file - All 3 items will have lead_id *9645813016256c1a1df46583e32a8a15* | lead id a1/a2 |  |
| A3.3 | url | Url from which restaurant info scraped | string | Present in website sources Should be null when the source is an APP | - |  |
| A3.4 | item_id | Unique ID for the menu items "b35c9367-e08e-4203-a6b3-d10b36e51db7" | UUID v4 | Should not repeat Can never be null Example: **"item_id":"4d8a4bbf-6719-4fc7-add6-204cc039a42c"** | id |  |
| A3.5 | item_name | E.g. McNuggets | string | item_name will never be null If there is an entry in A3 file with lead_id then item_name should be there 3.Example: **"item_name":"Beef Burger"** | name |  |
| A3.6 | item_description | “Cheeseburger with pickles and onions ” | string | If missing, validate against source - if the source does not have it, it should be null Example: "item_description":"Meat Burger" | description |  |
| A3.7 | item_price | E.g. 3.99 | numeric | Must have price If missing, validate against source - if the source does not have it, it should be null (not “0”) Example: "item_price":4000.0 Watch out for exceptions: decimal in south american sources or comma in France etc | promoPrice |  |
| A3.8 | currency | https://de.wikipedia.org/wiki/ISO_4217 | String | Must have currency value This field will never be null Example: "currency":"IQD" | Hardcoded CFA |  |
| A3.9 | item_is_promoted | Any kind of “favorite”or Promotional flag, e.g. stars at deliveroo for popular | boolean | item_is_promoted will always be Either True or False, if menu item falls under Promo, offer etc then the flag will be set to True If the source doesn’t have this information available, this should be set to " **item_is_promoted":false** Example: "item_is_promoted":true | promoTypes |  |
| A3.10 | menu_category (added September 2022) | The category a menu item is listed under. Examples: “Sides”, “Noodles”, “Picked for you” To be included in the sources under tab “menu_category & menu_item_image urls” in external client sheet AND any new sources from October 2022 onwards | String | Check to see if these two fields apply to this source If missing, validate against source - if the source does not have it, it should be null | categories > name |  |
| A3.11 | menu_item_image_url (added September 2022) | Image url examples: elmenus - https://s3-eu-west-1.amazonaws.com/elmenusv5-stg/Normal/32356bc6-25de-490a-9043-b5bcde0e4427.jpg bistro - https://img.bistro.sk/foto/NjB4NjAvYmlz/m_r3zr0a_saigon.jpg?st=TInrGeSJOASRaqoxkmMQ3j5SD07QA1rRfgsq0l2GLGw&ts=1660384867&e=0 To be included in the sources under tab “menu_category & menu_item_image urls” in external client sheet AND any new sources from October 2022 onwards | String | Check to see if these two fields apply to this source If missing, validate against source - if the source does not have it, it should be null | picture > uri |  |
| A3.12 | original_price (added June 2023) | When item_is_promoted =TRUE and then item_price equals the price shared on the site at that time and original_price is what the price was before the promotion | numeric | Must always have this field | price |  |
| A3.13 | Free Field |  | Hash | Should contain extra information required by client about the restaurant. It could contain one of more fields inside of it. If client didn’t require extra information for that source, this will be: **“free_field":null** If the value of any of the fields inside free_field is missing, it should be **null** . | - |  |