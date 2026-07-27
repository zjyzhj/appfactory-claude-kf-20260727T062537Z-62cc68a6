<t3_map_dispatch>
stage: pm_docs
native_agent: pm-agent
agent_id: PMAgent
attempt: 1
required_output_file: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-1/MAP.md
working_directory: use the controller repository root in stage_path_hints_json; do not use an isolated worktree.
identity: use the project-level native agent definition already loaded for this subagent.
Do NOT expect a full agents/*/prompt.md paste in this message.
Product/contract entry: open upstream MAP path(s) below first; follow MAP reading order and critical inputs.
If a required upstream MAP or MAP-listed critical input is missing/unreadable, write final MAP.md with Status/Verdict: blocked and literal map_inputs_incomplete:<what> — do not invent product direction.
Handoff: progressive Markdown only (docs/agent-io-markdown.md, docs/map-protocol.md).
Liveness: write MAP.progress.md or draft MAP early; update after work chunks; final MAP.md ready|blocked|partial|skipped before exit (never silent wait).
Skills whitelist: product-design-user-context, product-design-index, product-design-get-context, pmagent-appstore-competition-scan, pmagent-demand-radar, pmagent-office-hours, pmagent-value-score, product-design-research, product-design-ideate, creative-production-explore, creative-production-moodboard, creative-production-scene, creative-production-shot, pmagent-product-goal-bundle-v2, product-motion-language, app-review-risk, product-design-audit, product-design-design-qa.
upstream_maps: (none — e.g. pm_docs bootstrap from objective/goal.md)
stage_path_hints_json:
{"attempt": 1, "dedupe_list_command": "PYTHONPATH=. python3 bin/factory dedupe-list --limit 200", "dedupe_store": "/Users/zhoujinyu/.claude/app-factory/pmagent_global_dedupe.sqlite", "goal_md": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/goal/goal.md", "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-1/MAP.md", "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/PMAgent/playbooks/pm_docs.md", "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/PMAgent/prompt.core.md", "run_id": "kf-20260727T062537Z-62cc68a6", "stage": "pm_docs", "working_directory": "/Volumes/zjySD/claude-app-factory"}
</t3_map_dispatch>