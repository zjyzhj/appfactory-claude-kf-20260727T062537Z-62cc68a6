<claude_dispatch>

You are a bounded AppFactory stage agent (T2/headless CLI path).

Progressive disclosure: open role_prompt_ref (core) fully, then role_playbook_ref when set; then upstream MAPs / stage_paths. Do not invent role rules from memory.

role_prompt_ref: /Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/prompt.core.md

role_playbook_ref: /Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/playbooks/rough_app.md

agent_id: FactoryPackageOwner

Handoff is progressive Markdown only. docs/agent-io-markdown.md is authoritative.

Liveness: write MAP.progress.md or draft MAP early; final MAP.md ready|blocked|partial|skipped before exit.

Write root MAP.md to: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/rough_app/attempt-1/MAP.md

Rough: read PM MAP then build/* only; skip research/; OPEN-BOOK: upstream_map_checklist is the frozen QA test plan — build to it; frames if present; wire In-app image slots from design.md.

Factory checks process finish + MAP exists (not body schema).

Skills whitelist: appfactory-runtime-io, factory-package-owner, factory-rough-app-builder, build-ios-apps, swiftui-ui-patterns, swiftui-view-refactor, taste-skill, ios-visual-assets-implementation, product-motion-language, ios_runtime_acceptance, ios-simulator-browser, ios-debugger-agent, kimi-coding-implementation.

</claude_dispatch>

<stage_paths>

{
  "agent_io_ref": "/Volumes/zjySD/claude-app-factory/docs/agent-io-markdown.md",
  "agent_name": "FactoryPackageOwner",
  "attempt": 1,
  "frame_paths": [
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_compare.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_home.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_home_empty.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_paywall.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_verdict.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/frames/frame_walkthrough.png"
  ],
  "github_repo_name": "appfactory-claude-kf-20260727T062537Z-62cc68a6",
  "handoff": "MAP.md",
  "map_protocol_ref": "/Volumes/zjySD/claude-app-factory/docs/map-protocol.md",
  "note": "Read PM MAP then build/* on demand. OPEN-BOOK: upstream_map_checklist is the frozen QA test plan — build to satisfy it with real implementations (shells fail the QA runtime pass and return as bugs). If upstream_map_pm_visuals / frame_paths are set, read those key-frame references early for visual reconstruction (layout/density/differentiation) and record Upstream visuals in your MAP (frames_read or frames_ignored). If slot_asset_paths is set, those files are embeddable slot rasters (not whole-screen frames) — copy into Assets.xcassets and wire Image() for matching design.md slot_id; do not ignore them in favor of weak placeholders when present. Truth priority: build text (routes/states/ACC) > slot assets > frames > free taste. Mandatory: implement design.md In-app image slots (app_icon, hero, empty_illustration, photo_or_media) via ios-visual-assets-implementation; no separate visual_assets stage.",
  "objective": "由 PMAgent 基于真实市场证据自主选定有差异化机会的 iOS 本地零账号 App 产品方向",
  "product_repo_dir": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/product",
  "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/rough_app/attempt-1/MAP.md",
  "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/playbooks/rough_app.md",
  "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/prompt.core.md",
  "run_id": "kf-20260727T062537Z-62cc68a6",
  "skill_targets": [
    "appfactory-runtime-io",
    "factory-package-owner",
    "factory-rough-app-builder",
    "build-ios-apps",
    "swiftui-ui-patterns",
    "swiftui-view-refactor",
    "taste-skill",
    "ios-visual-assets-implementation",
    "product-motion-language",
    "ios_runtime_acceptance",
    "ios-simulator-browser",
    "ios-debugger-agent",
    "kimi-coding-implementation"
  ],
  "slot_asset_paths": [
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/slots/app_icon.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/slots/home_hero.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/slots/viewings_empty_illustration.png"
  ],
  "stage": "rough_app",
  "upstream_map": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-2/MAP.md",
  "upstream_map_checklist": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/checklist/attempt-2/MAP.md",
  "upstream_map_pm_visuals": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/MAP.md",
  "working_directory": "/Volumes/zjySD/claude-app-factory"
}

</stage_paths>