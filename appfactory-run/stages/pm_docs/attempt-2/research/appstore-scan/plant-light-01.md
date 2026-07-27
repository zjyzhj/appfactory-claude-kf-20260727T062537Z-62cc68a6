# App Store Competition Scan · plant-light-01

## Candidate
- **one_liner:** Camera-based live light meter for indoor gardeners: real-time lux/PPFD-style reading mapped to plant light needs, placement scoring across rooms
- **core_job:** measure live light with the camera and match spots to plant light requirements
- **domain_objects:** spot, reading, plant profile, placement
- **primary_interaction:** point camera at a spot -> live light grade -> match against plant needs -> save placement verdict
- **wedge_hypothesis:** generic lux meters ignore plants; plant apps are watering reminders; nobody answers 'will this spot keep this plant alive' live

## Query envelope

| seed | result_count | notes |
|------|--------------|-------|
| light meter plant | 23 | ok |
| lux meter | 24 | ok |
| plant light | 24 | ok |
| PPFD meter | 25 | ok |
| measure live light with the camera and match spots to plant light requirements | 25 | ok |

- country: `us`
- raw_status: `ok`
- fetched_at: `2026-07-27T14:31:42+08:00`
- cache_hit: `False`

## Evidence table (deduped by trackId)

| rank | name | trackId | url | rating | ratingCount | updated | layer | why_similar | why_not_our_wedge | zombie |
|------|------|---------|-----|--------|-------------|---------|-------|-------------|-------------------|--------|
| 1 | PictureThis - Plant Identifier | 1252497129 | https://apps.apple.com/us/app/picturethis-plant-identifier/id1252497129?uo=4 | 4.80525 | 1099939 | 2026-07-22T01:37:44Z | L3 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 2 | Planta: Plant & Garden Care | 1410126781 | https://apps.apple.com/us/app/planta-plant-garden-care/id1410126781?uo=4 | 4.75542 | 112452 | 2026-07-04T04:24:15Z | L3 | similar core job language; shared domain objects; similar primary interaction... | insufficient evidence of wedge gap | no |
| 3 | Plantion - Plant Identifier | 1673397906 | https://apps.apple.com/us/app/plantion-plant-identifier/id1673397906?uo=4 | 4.2571 | 9689 | 2023-09-23T16:16:45Z | L3 | similar core job language; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 4 | Photone - Grow Light Meter | 1450079523 | https://apps.apple.com/us/app/photone-grow-light-meter/id1450079523?uo=4 | 4.62167 | 4874 | 2026-07-15T07:53:21Z | L3 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 5 | Light Meter LM-3000 | 1554264761 | https://apps.apple.com/us/app/light-meter-lm-3000/id1554264761?uo=4 | 4.51304 | 2530 | 2026-07-24T06:45:42Z | L3 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 6 | Light Meter For Plants | 6755839439 | https://apps.apple.com/us/app/light-meter-for-plants/id6755839439?uo=4 | 3.28571 | 7 | 2026-03-09T08:59:46Z | L3 | similar core job language; shared domain objects; similar primary interaction... | insufficient evidence of wedge gap | no |
| 7 | Light Meter: Lux & Plants | 6761759935 | https://apps.apple.com/us/app/light-meter-lux-plants/id6761759935?uo=4 | 5.0 | 2 | 2026-04-17T06:22:02Z | L3 | similar core job language; shared domain objects; similar primary interaction... | insufficient evidence of wedge gap | no |
| 8 | Light Meter Photography Film | 6478221966 | https://apps.apple.com/us/app/light-meter-photography-film/id6478221966?uo=4 | 4.76667 | 30 | 2026-06-24T04:33:08Z | L2 | similar core job language; shared domain objects; similar primary interaction | insufficient evidence of wedge gap | no |
| 9 | Plant Light Meter: Lux & PPFD | 1628111038 | https://apps.apple.com/us/app/plant-light-meter-lux-ppfd/id1628111038?uo=4 | 1.72727 | 11 | 2026-06-25T15:39:57Z | L2 | similar core job language; shared domain objects; similar primary interaction... | insufficient evidence of wedge gap | no |
| 10 | Light Meter・Lux Meter | 6759604310 | https://apps.apple.com/us/app/light-meter-lux-meter/id6759604310?uo=4 | 5.0 | 2 | 2026-07-13T06:42:58Z | L2 | similar core job language; shared domain objects; similar primary interaction | insufficient evidence of wedge gap | no |
| 11 | LuxMeasure: Light Meter | 6761436100 | https://apps.apple.com/us/app/luxmeasure-light-meter/id6761436100?uo=4 | 0 | 0 | 2026-04-01T23:05:27Z | L2 | similar core job language; shared domain objects; similar primary interaction... | insufficient evidence of wedge gap | no |
| 12 | VIVOSUN | 1600813756 | https://apps.apple.com/us/app/vivosun/id1600813756?uo=4 | 4.73555 | 8009 | 2026-07-24T20:02:29Z | L1 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 13 | Lux Light Meter Pro | 1292598866 | https://apps.apple.com/us/app/lux-light-meter-pro/id1292598866?uo=4 | 3.94536 | 5106 | 2025-10-10T06:37:18Z | L1 | name/category adjacency | wedge moment not evident in listing; primary interaction not mirrored | no |
| 14 | Plant Light Meter | 1213431133 | https://apps.apple.com/us/app/plant-light-meter/id1213431133?uo=4 | 4.57223 | 1073 | 2022-10-13T19:24:25Z | L1 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 15 | Pocket Light Meter | 381698089 | https://apps.apple.com/us/app/pocket-light-meter/id381698089?uo=4 | 4.4555 | 1045 | 2025-02-19T11:21:48Z | L1 | similar core job language | wedge moment not evident in listing | no |
| 16 | Lightme - Lightmeter | 1509033790 | https://apps.apple.com/us/app/lightme-lightmeter/id1509033790?uo=4 | 4.85164 | 856 | 2026-05-26T18:50:43Z | L1 | similar core job language; similar primary interaction | wedge moment not evident in listing | no |
| 17 | Lux Light Meter Pro for Photo | 6447008772 | https://apps.apple.com/us/app/lux-light-meter-pro-for-photo/id6447008772?uo=4 | 4.75113 | 442 | 2026-06-25T08:33:56Z | L1 | similar core job language; similar primary interaction; overlapping wedge/moment | insufficient evidence of wedge gap | no |
| 18 | Lux Light Meter for Mobile | 1638732220 | https://apps.apple.com/us/app/lux-light-meter-for-mobile/id1638732220?uo=4 | 4.48018 | 227 | 2025-02-15T15:44:00Z | L1 | name/category adjacency | wedge moment not evident in listing | no |
| 19 | Luxmeter - Lux Light Meter | 6746211051 | https://apps.apple.com/us/app/luxmeter-lux-light-meter/id6746211051?uo=4 | 4.40291 | 206 | 2025-09-24T21:00:20Z | L1 | name/category adjacency | wedge moment not evident in listing | no |
| 20 | Lux Light Meter & Photometer | 6504260709 | https://apps.apple.com/us/app/lux-light-meter-photometer/id6504260709?uo=4 | 4.84772 | 197 | 2026-07-15T07:41:40Z | L1 | similar core job language | wedge moment not evident in listing | no |

## Axis A · Collision
- **level:** `high`
- **notes:** active L2=4 L3=7 L1=18; zombies=1
- **nearest_clones:**
  - PictureThis - Plant Identifier (`1252497129`, L3) — https://apps.apple.com/us/app/picturethis-plant-identifier/id1252497129?uo=4
  - Planta: Plant & Garden Care (`1410126781`, L3) — https://apps.apple.com/us/app/planta-plant-garden-care/id1410126781?uo=4
  - Plantion - Plant Identifier (`1673397906`, L3) — https://apps.apple.com/us/app/plantion-plant-identifier/id1673397906?uo=4
  - Photone - Grow Light Meter (`1450079523`, L3) — https://apps.apple.com/us/app/photone-grow-light-meter/id1450079523?uo=4
  - Light Meter LM-3000 (`1554264761`, L3) — https://apps.apple.com/us/app/light-meter-lm-3000/id1554264761?uo=4

## Axis B · Competitive heat
- **band:** `red`
- **head_structure:** `concentrated`
- **moat_types:** network, hardware
- **zombie_ratio:** 0.0333
- **notes:** pool=29 top1=1099939 top3_sum=1222080

## Axis C · V0 survivability
- **band:** `low`
- **needs_network_for_aha:** `False`
- **underserved_moment:** generic lux meters ignore plants; plant apps are watering reminders; nobody answers 'will this spot keep this plant alive' live
- **wedge_vs_top_n:**
  - **PictureThis - Plant Identifier** (`1252497129`): insufficient evidence of wedge gap
  - **Planta: Plant & Garden Care** (`1410126781`): insufficient evidence of wedge gap
  - **Plantion - Plant Identifier** (`1673397906`): insufficient evidence of wedge gap
- **notes:** factory v0 is local zero-account; network moats are hostile

## Verdict
- **decision:** `reject_saturated_clone`
- **required_actions:**
  - Drop this candidate; pick next shortlist item
- **blockers:** _(none)_

## Package write-back (if selected)

If verdict is `proceed_narrow_wedge` and this candidate is selected at S3:
1. Copy wedge_vs_top_n into `build/product.md` §市场供给与立场 (conclusions only).
2. Mirror non-compete surfaces into `build/non-goals.md`.
3. Do **not** link this research file from `MAP.md`.
