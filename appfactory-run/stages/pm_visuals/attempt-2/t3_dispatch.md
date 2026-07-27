<t3_map_dispatch>
stage: pm_visuals
native_agent: pm-visuals-agent
agent_id: PMVisualsAgent
attempt: 2
required_output_file: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/MAP.md
working_directory: use the controller repository root in stage_path_hints_json; do not use an isolated worktree.
identity: use the project-level native agent definition already loaded for this subagent.
Do NOT expect a full agents/*/prompt.md paste in this message.
Product/contract entry: open upstream MAP path(s) below first; follow MAP reading order and critical inputs.
If a required upstream MAP or MAP-listed critical input is missing/unreadable, write final MAP.md with Status/Verdict: blocked and literal map_inputs_incomplete:<what> — do not invent product direction.
Handoff: progressive Markdown only (docs/agent-io-markdown.md, docs/map-protocol.md).
Liveness: write MAP.progress.md or draft MAP early; update after work chunks; final MAP.md ready|blocked|partial|skipped before exit (never silent wait).
Skills whitelist: claude-gpt-image.
upstream_maps:
  - upstream_map_pm: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-2/MAP.md
stage_path_hints_json:
{"attempt": 2, "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/MAP.md", "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/PMVisualsAgent/playbooks/pm_visuals.md", "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/PMVisualsAgent/prompt.core.md", "run_id": "kf-20260727T062537Z-62cc68a6", "stage": "pm_visuals", "working_directory": "/Volumes/zjySD/claude-app-factory"}
</t3_map_dispatch>