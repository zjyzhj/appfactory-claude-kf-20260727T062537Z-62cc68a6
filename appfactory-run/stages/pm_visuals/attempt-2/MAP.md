# pm_visuals — TourWise key frames

Status: ready

attempt-2 = **g1(product_shape)-refine reconcile, not a fresh generation**. pm_docs attempt-2 changed only 6 IAP copy spots (seed 3 → 100; tiers 10/30 → product 473900 = 110 credits / $0.99, 473901 = 210 credits / $1.99; restore: no). `build/design.md` is byte-identical across attempts (verified by diff of attempt-1 vs attempt-2 build trees) — frame inventory, palette, and slot table unchanged.

Reconcile result: 5/6 frames + all 3 slots + their prompts verified free of commercialization copy (visually re-checked each raster) and were carried over from attempt-1 as hard links, receipts intact. **Only `frame_paywall` contained stale copy** (balance "2", "1 Export Credit $0.99", "5 Export Credits $3.99", Restore Purchases link) and was regenerated once via ClaudeGPTImage (`claude-gpt-image`) HTTP fallback — this time `cred_source=factory_keychain` against factory relay `http://38.143.109.229:48761/v1`, model `gpt-image-2`. New raster visually verified: balance 100, 110 credits / $0.99, 210 credits / $1.99 with Best value pill, no Restore link, note matches contract (1 credit per export, never expire, on-device render).

## Frames (whole-screen layout references for rough_app multimodal)

| frame_id | route_id | raster | receipt | size | status | source |
|----------|----------|--------|---------|------|--------|--------|
| frame_home | tab_viewings | frames/frame_home.png | frames/frame_home.png.receipt.json | 853x1844 | done | reused attempt-1 |
| frame_home_empty | tab_viewings | frames/frame_home_empty.png | frames/frame_home_empty.png.receipt.json | 863x1823 | done | reused attempt-1 |
| frame_walkthrough | room_capture | frames/frame_walkthrough.png | frames/frame_walkthrough.png.receipt.json | 853x1844 | done | reused attempt-1 |
| frame_compare | compare_board | frames/frame_compare.png | frames/frame_compare.png.receipt.json | 853x1844 | done | reused attempt-1 |
| frame_verdict | verdict_card | frames/frame_verdict.png | frames/frame_verdict.png.receipt.json | 862x1825 | done | reused attempt-1 |
| frame_paywall | paywall | frames/frame_paywall.png | frames/frame_paywall.png.receipt.json | 853x1844 | done | **regenerated for attempt-2 IAP copy** |

Prompts: `prompts/<frame_id>.txt` per frame (`frame_paywall.txt` rewritten for attempt-2; other five unchanged from attempt-1).

## Slot assets (embeddable rasters, no UI chrome)

| slot_id | kind | raster | status | notes |
|---------|------|--------|--------|-------|
| app_icon | app_icon | slots/app_icon.png | done | reused attempt-1; 1254x1254; needs resize to 1024 for AppIcon imageset |
| home_hero | hero | slots/home_hero.png | done | reused attempt-1; 1774x887 (2:1); pairs with asset `hero_home` |
| viewings_empty_illustration | empty_illustration | slots/viewings_empty_illustration.png | done | reused attempt-1; 1254x1254; pairs with asset `empty_viewings` |

Prompts: `prompts/slot-<slot_id>.txt` (unchanged from attempt-1). Intentionally not generated: `room_photo_slot`, `detail_photo_strip`, `verdict_card_render` (user-capture / local-render per design.md), `criterion_icons` (SF Symbol mapping per design.md).

## Reading order for rough_app

1. `frames/` — IA / density / palette reference per route (whole-screen; do NOT embed as assets).
2. `slots/` — Asset Catalog wiring for `hero_home`, `empty_viewings`, AppIcon.
3. `prompts/` — regeneration seeds.
4. `MAP.progress.md` — reconcile queue log.

## Gaps

- Frame canvas is relay-native ~853x1844 rather than 640x1392 (same iPhone-portrait ratio; no layout impact for multimodal reference).
- app_icon needs downscale to 1024x1024 at Asset Catalog wiring time.
