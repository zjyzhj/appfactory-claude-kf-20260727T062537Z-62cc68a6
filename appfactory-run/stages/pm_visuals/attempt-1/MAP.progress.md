# pm_visuals progress — attempt 1 (TourWise)

Queue: 6 frames (serial) + 3 slot rasters (best-effort).

## Frames
| frame_id | route_id | prompt | raster | status |
|----------|----------|--------|--------|--------|
| frame_home | tab_viewings | prompts/frame_home.txt | frames/frame_home.png | done |
| frame_home_empty | tab_viewings | prompts/frame_home_empty.txt | frames/frame_home_empty.png | done |
| frame_walkthrough | room_capture | prompts/frame_walkthrough.txt | frames/frame_walkthrough.png | done |
| frame_compare | compare_board | prompts/frame_compare.txt | frames/frame_compare.png | done |
| frame_verdict | verdict_card | prompts/frame_verdict.txt | frames/frame_verdict.png | done |
| frame_paywall | paywall | prompts/frame_paywall.txt | frames/frame_paywall.png | done |

## Slots (best-effort)
| slot_id | kind | prompt | raster | status |
|---------|------|--------|--------|--------|
| app_icon | app_icon | prompts/slot-app_icon.txt | slots/app_icon.png | done |
| home_hero | hero | prompts/slot-home_hero.txt | slots/home_hero.png | done |
| viewings_empty_illustration | empty_illustration | prompts/slot-viewings_empty_illustration.txt | slots/viewings_empty_illustration.png | done |

Notes: photo_or_media slots (room_photo_slot, detail_photo_strip, verdict_card_render) are user-capture/local-render — intentionally not generated.
