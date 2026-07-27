<t3_map_dispatch>
stage: checklist
native_agent: final-gate-agent
agent_id: FinalGateAgent
attempt: 1
required_output_file: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/checklist/attempt-1/MAP.md
working_directory: use the controller repository root in stage_path_hints_json; do not use an isolated worktree.
identity: use the project-level native agent definition already loaded for this subagent.
Do NOT expect a full agents/*/prompt.md paste in this message.
Product/contract entry: open upstream MAP path(s) below first; follow MAP reading order and critical inputs.
If a required upstream MAP or MAP-listed critical input is missing/unreadable, write final MAP.md with Status/Verdict: blocked and literal map_inputs_incomplete:<what> — do not invent product direction.
Handoff: progressive Markdown only (docs/agent-io-markdown.md, docs/map-protocol.md).
Liveness: write MAP.progress.md or draft MAP early; update after work chunks; final MAP.md ready|blocked|partial|skipped before exit (never silent wait).
Skills whitelist: appfactory-runtime-io.
Process docs language: MAP.md/checks.md human prose = zh-CN for operator audit; keep Status/Verdict/pass|block/## Gaps/check_id/blocker codes English; product UI copy stays en-US (do not Chinese-ize app strings).
upstream_maps:
  - upstream_map_pm: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-1/MAP.md
stage_path_hints_json:
{"acceptance_policy": {"acceptance_policy_ref": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/acceptance_policy.v1.json", "acceptance_policy_sha256": "cb56b5d7daa90d2173a7d2eb10d6b10329b123f1b668f599ee933660c911651e", "evidence_skill": "ios_runtime_acceptance", "mode": "runtime_verification_required", "simulator_must_not_claim_pass": false, "simulator_runtime_required": true}, "attempt": 1, "product_repo_dir": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/product", "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/checklist/attempt-1/MAP.md", "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/FinalGateAgent/playbooks/checklist.md", "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/FinalGateAgent/prompt.core.md", "run_id": "kf-20260727T062537Z-62cc68a6", "stage": "checklist", "working_directory": "/Volumes/zjySD/claude-app-factory"}
</t3_map_dispatch>