# pm_visuals — TourWise key frames

Status: ready

All 6 design.md Visual frames generated as real PNGs; 3 embeddable slot rasters delivered (best-effort set complete). Backend: primary Codex wrapper unavailable (codex auth.json API key rejected 401 by api.openai.com; factory relay keychain entry absent on this machine) → used ClaudeGPTImage (`claude-gpt-image`) HTTP fallback against factory AI relay `http://38.143.109.229:48761/v1` with the codex string key, model `gpt-image-2`, one call per frame. Every raster validated (PNG signature, non-trivial payload) with adjacent `.png.receipt.json` ok=true.

Note: relay returns its own portrait canvas (~851x1844, iPhone-portrait ratio ~0.46) instead of requested 640x1392; ratio preserved, content verified visually. Slot rasters: app_icon/empty illustration ~1254x1254, hero 1774x887 (2:1 wide).

## Frames (whole-screen layout references for rough_app multimodal)

| frame_id | route_id | raster | receipt | size | status |
|----------|----------|--------|---------|------|--------|
| frame_home | tab_viewings | frames/frame_home.png | frames/frame_home.png.receipt.json | 853x1844 | done |
| frame_home_empty | tab_viewings | frames/frame_home_empty.png | frames/frame_home_empty.png.receipt.json | 863x1823 | done |
| frame_walkthrough | room_capture | frames/frame_walkthrough.png | frames/frame_walkthrough.png.receipt.json | 853x1844 | done |
| frame_compare | compare_board | frames/frame_compare.png | frames/frame_compare.png.receipt.json | 853x1844 | done |
| frame_verdict | verdict_card | frames/frame_verdict.png | frames/frame_verdict.png.receipt.json | 862x1825 | done |
| frame_paywall | paywall | frames/frame_paywall.png | frames/frame_paywall.png.receipt.json | 851x1847 | done |

Prompts: `prompts/<frame_id>.txt` per frame.

## Slot assets (embeddable rasters, no UI chrome)

| slot_id | kind | raster | status | notes |
|---------|------|--------|--------|-------|
| app_icon | app_icon | slots/app_icon.png | done | 1254x1254; warm paper bg, brass house + star; needs resize to 1024 for AppIcon imageset |
| home_hero | hero | slots/home_hero.png | done | 1774x887 (2:1); warm living-room window light; pairs with asset `hero_home` + gradient overlay |
| viewings_empty_illustration | empty_illustration | slots/viewings_empty_illustration.png | done | 1254x1254; polaroid stack + brass star on paper bg; pairs with asset `empty_viewings` |

Prompts: `prompts/slot-<slot_id>.txt`. Intentionally not generated: `room_photo_slot`, `detail_photo_strip`, `verdict_card_render` (user-capture / local-render per design.md), `criterion_icons` (SF Symbol mapping per design.md).

## Reading order for rough_app

1. `frames/` — IA / density / palette reference per route (whole-screen; do NOT embed as assets).
2. `slots/` — Asset Catalog wiring for `hero_home`, `empty_viewings`, AppIcon.
3. `prompts/` — regeneration seeds.
4. `MAP.progress.md` — serial queue log.

## Gaps

- Frame canvas is relay-native ~853x1844 rather than 640x1392 (same iPhone-portrait ratio; no layout impact for multimodal reference).
- app_icon needs downscale to 1024x1024 at Asset Catalog wiring time.
