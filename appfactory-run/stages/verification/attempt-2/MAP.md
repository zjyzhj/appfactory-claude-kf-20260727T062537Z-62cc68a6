# Verification · TourWise(attempt-2 · QA 回归)

- Verdict: ready
- Mode: runtime_verification_required(simulator_runtime REQUIRED · evidence_skill ios_runtime_acceptance)
- Standard: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/checklist/attempt-2/MAP.md(+ checks.md)
- Repo: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/product
- Tested commit: 504e1bf02888521657de38d8ac8f4c6d90a1c54f(回归时 HEAD=208f740,diff 仅 appfactory-run 上下文发布文件,产品源码零变更;attempt-1 证据继续有效)
- Bug bus: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/qa/bugs.jsonl(open: 0 / merged: 0 / verified: 5)
- Evidence root: ../attempt-1/evidence(49 张截图 + 2 段录屏 + 构建/测试日志 + 沙盒 store 快照 + Photos 读回;SHA256SUMS.txt 回归时全量校验 0 失败)

## 回归范围(zh-CN)

本 attempt 为 patch 波次后的 **failed-only 回归 + 受影响面 smoke**,非全量重跑:attempt-1 仅 2 项 block(product_maturity:feature_expansion / product_maturity:functional_completeness_final_review),均为 PackageDelivery MAP 文档缺口;patch 已在 rough_app MAP 补入两节 manifest(bug b-8d7126e43a9d / b-3966df17f43a → merged)。本 attempt 重评该 2 项并做受影响面 smoke;其余 26 项 pass 结论沿自 attempt-1(产品源码未变,运行时证据哈希校验完好,无需重跑模拟器)。

## 重评两项(回归新判)

- product_maturity:feature_expansion: pass — patch 后 rough_app MAP 第 85 行 `## Feature expansion consumption` 节含合规 JSON manifest:`product_shape: already_mature` + `gap_assessment`(字面覆盖核心任务生命周期/回访价值/持久化/空·加载·成功·错误·中断·恢复态齐备论证)+ 5 个 area(criteria_system / weight_profiles / evidence_photos / normalized_weighted_ranking / verdict_render_export),满足清单 A2 "product_shape / gap 评估 / 至少一行 area" 字面要求;JSON 经解析校验通过;各 area 证据引用 attempt-1 运行时终审结论,already_mature 成立 — evidence: stages/rough_app/attempt-1/MAP.md:85-123, stages/verification/attempt-1/MAP.md — kinds: source — layer: L2
- product_maturity:functional_completeness_final_review: pass — patch 后 rough_app MAP 第 125 行 `## Functional completeness final review` 节含合规 JSON manifest:10 个 area 全覆盖(viewing_create_and_list / walkthrough_capture / viewing_detail_management / criteria_management / weight_profiles / compare_and_ranking / verdict_render_export / credits_iap_paywall / settings_privacy_legal / app_shell_navigation),每 area 六字段(area_id/status/entry_point/state_action_outcome/chain_connection/evidence)齐全且全部 status=pass、均带证据引用,无未审/无证据/blocked area,满足清单 A17 字面要求;JSON 经解析校验通过 — evidence: stages/rough_app/attempt-1/MAP.md:125-216, stages/verification/attempt-1/MAP.md — kinds: source — layer: L2

## 沿用结论(26 项,attempt-1 全量证据锚点)

以下 26 项 pass 结论逐字沿自 stages/verification/attempt-1/MAP.md(tested commit 同源、证据哈希完好),逐项理由与证据路径以该 MAP 为准:

- product_maturity:core_value_and_feature_completeness: pass — 核心闭环五段端到端运行时走通,14 条 route 点击级到达 — kinds: simulator_screenshot, simctl_launch, runtime_readback — layer: L1
- product_maturity:information_architecture_and_navigation: pass — 4 tab 逐 tab 截图 + 跨 tab 状态保留运行时实证 — kinds: simulator_screenshot, runtime_readback — layer: L1
- product_maturity:interaction_and_state_quality: pass — 空态/校验阻存/删除确认/购买失败 toast 等全态运行时或源码逐字佐证 — kinds: simulator_screenshot, source — layer: L1+L2
- product_maturity:layout_accessibility_and_responsiveness: pass — iPhone SE 2nd gen 无溢出 + a11y label 语义回读;320×568 环境限制已如实记录 — kinds: simulator_screenshot — layer: L1+L2
- product_maturity:visual_hierarchy_and_design_polish: pass — "Evidence board on warm paper" 全表面一致,无模板感 — kinds: simulator_screenshot — layer: L1+L2
- product_maturity:feature_expressive_ui_ux_and_motion: pass — 5 moment 录屏实证 + Reduce Motion 等价 — kinds: simulator_video, simulator_screenshot — layer: L1+L2
- product_maturity:workflow_coherence_and_lifecycle: pass — 状态机 + 中断恢复 + 杀进程重进数据完整运行时走通 — kinds: simulator_screenshot, runtime_readback — layer: L1+L2
- ios_delivery:consumable_iap: pass — yanran 两档字面接线 + 账本运行时回读三重一致,无 Restore/订阅/解锁 — kinds: source, simulator_screenshot, runtime_readback — layer: L0+L1+L2
- ios_delivery:legal_webviews: pass — 两独立 https WebView + 失败友好态运行时可达 — kinds: source, simulator_screenshot — layer: L1
- ios_delivery:functional_images: pass — 5 页图片绑定真实域记录,≥3 页主图占 30–70% 且保留功能上下文 — kinds: simulator_screenshot — layer: L1
- ios_delivery:camera_permission: pass — plist 字面 + JIT + syntheticCapture seam granted 路径走通 + denied 三继续项源码逐字 — kinds: simulator_screenshot, runtime_readback, source — layer: L0+L1
- ios_delivery:photo_library_read_write_permission: pass — 读 PHPicker 选图 + 写 Save to Photos 相册读回 2160×2700 PNG — kinds: simulator_screenshot, runtime_readback, source — layer: L1
- ios_delivery:microphone_permission_boundary: pass — 缺席分支证明集齐全(plist/API/PrivacyInfo/单测/运行时零弹窗) — kinds: source, simulator_screenshot — layer: L0+L1
- ios_delivery:app_tracking_transparency: pass — 缺席分支证明集齐全,NSPrivacyTracking=false — kinds: source, simulator_screenshot — layer: L0+L1
- ios_delivery:keyboard_dismissal: pass — 全部输入面 scrollDismissesKeyboard + onSubmit 运行时实测 — kinds: source, simulator_screenshot — layer: L1
- tourwise:walkthrough_lifecycle: pass — 步进/乱序/跳过/Finish 汇总/中断 Resume 运行时走通 — kinds: simulator_screenshot — layer: L1
- tourwise:weighted_scoring_formula: pass — 公式源码逐行一致 + 20/20 单测 + 运行时缺分 "—"/Σ≠100 阻存 — kinds: source, simulator_screenshot — layer: L0+L1
- tourwise:criteria_system: pass — 9 内置 seed + 内置不可删 + 自定义即时生效运行时可见 — kinds: simulator_screenshot, source — layer: L1
- tourwise:cascade_delete: pass — 确认文案逐字 + 级联删除文件系统级回读 — kinds: simulator_screenshot, runtime_readback — layer: L1
- tourwise:verdict_card_export: pass — 渲染卡 + Save 扣 1 三重一致 + 降级/ denied 分支源码佐证 — kinds: simulator_screenshot, runtime_readback, source — layer: L1
- tourwise:image_slot_app_icon: pass — AppIcon.appiconset 存在且被构建引用 — kinds: source, build — layer: L0
- tourwise:image_slot_home_hero: pass — hero 槽运行时可见 + 兜底源码存在 — kinds: simulator_screenshot, source — layer: L1
- tourwise:image_slot_empty_illustration: pass — 空态插画 + CTA 双场景运行时可见 — kinds: simulator_screenshot, source — layer: L1
- tourwise:image_slot_photo_media: pass — room_capture/detail/verdict 三照片槽路径运行时全证 — kinds: simulator_screenshot — layer: L1
- tourwise:local_only_privacy_surface: pass — 本地 JSON + privacy 路由 + Delete All Data 双重确认运行时走通 — kinds: simulator_screenshot, runtime_readback, source — layer: L1
- build:headless_xcodebuild: pass — BUILD SUCCEEDED + 20/20 单测 0 失败(sha256 绑定日志) — kinds: build — layer: L0

## 受影响面 smoke(回归附带核查)

- 两段 manifest JSON 均通过解析与字段断言(product_shape/gap_assessment/areas;A17 六字段 ×10 area 全 pass)——解析脚本输出 ALL_JSON_OK。
- rough_app MAP 其余章节(产品 repo/视觉系统/图片槽/构建证据/Known gaps)与 attempt-1 判读一致,patch 未引入新声明冲突。
- 产品仓 504e1bf..208f740 diff 仅 appfactory-run 状态与 evidence 发布文件,源码/资源/配置零变更;attempt-1 evidence/SHA256SUMS.txt 全量复核 0 失败。
- Bug 总线终态:open 0 / merged 0 / verified 5(b-3c387e96204f、b-ede3d572b6fe、b-b7bbc1e29288 三条 L0 误报核销;b-8d7126e43a9d、b-3966df17f43a 本 attempt 转 verified)。

## Gaps

| gap_id | dimension | severity | evidence | suggested_node | note |
|--------|-----------|----------|----------|----------------|------|
| g2 | G6 | low | Sources/Theme.swift:29-34 | build_ui | 沿用 attempt-1:字体全部固定点级 token,不响应 Dynamic Type;AX3 下不裁切不重叠(字面成立)但弱视力用户无放大收益,建议后续改相对 text style;不阻塞放行 |
| g3 | G6 | low | stages/verification/attempt-1/MAP.md | verify | 沿用 attempt-1 环境限制备案:Simulator 无相机硬件(真 denied 仅源码佐证)、simctl 挂不了 .storekit(购买注入不可达)、320×568 设备不存在以 SE 2nd gen 375×667 替代 |
