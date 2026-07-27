<t3_map_dispatch>
stage: delivery
native_agent: delivery-reporter-agent
agent_id: DeliveryReporterAgent
attempt: 1
required_output_file: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/delivery/attempt-1/MAP.md
working_directory: use the controller repository root in stage_path_hints_json; do not use an isolated worktree.
identity: use the project-level native agent definition already loaded for this subagent.
Do NOT expect a full agents/*/prompt.md paste in this message.
Product/contract entry: open upstream MAP path(s) below first; follow MAP reading order and critical inputs.
If a required upstream MAP or MAP-listed critical input is missing/unreadable, write final MAP.md with Status/Verdict: blocked and literal map_inputs_incomplete:<what> — do not invent product direction.
Handoff: progressive Markdown only (docs/agent-io-markdown.md, docs/map-protocol.md).
Liveness: write MAP.progress.md or draft MAP early; update after work chunks; final MAP.md ready|blocked|partial|skipped before exit (never silent wait).
Skills whitelist: appfactory-runtime-io, human-delivery-report.
upstream_maps: (none — e.g. pm_docs bootstrap from objective/goal.md)
stage_path_hints_json:
{"attempt": 1, "product_repo_dir": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/product", "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/delivery/attempt-1/MAP.md", "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/DeliveryReporterAgent/playbooks/delivery.md", "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/DeliveryReporterAgent/prompt.core.md", "run_id": "kf-20260727T062537Z-62cc68a6", "stage": "delivery", "working_directory": "/Volumes/zjySD/claude-app-factory"}
</t3_map_dispatch>