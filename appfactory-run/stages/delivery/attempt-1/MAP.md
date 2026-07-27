# Delivery · TourWise

- Status: ready
- Product: TourWise — 本地优先、零账号的 iPhone 看房决策助手（现场拍证据照打分 → 可调权重横向对比 → 导出 Verdict 结论卡）；SwiftUI / StoreKit 2 consumable / 本地 JSON 持久化，无三方依赖。
- Repo: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/product · https://github.com/zjyzhj/appfactory-claude-kf-20260727T062537Z-62cc68a6
- Verification: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/verification/attempt-2/MAP.md → ready（28/28 pass，runtime_verification_required，真 Simulator 证据）
- Package: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/rough_app/attempt-1/MAP.md（patch 波次：/Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/patch/attempt-1/MAP.md，仅文档 manifest，产品源码零变更）
- Checklist: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/checklist/attempt-2/MAP.md（+ checks.md）
- Visual: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_visuals/attempt-2/（6 帧 + 11 slots，validated）
- PM manual: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-2/MAP.md（build/* 八章）

## Operator summary

- 验收链全绿：checklist(attempt-2) → rough_app → patch → verification(attempt-2) 终判 **ready，28/28 pass**，含全部 runtime_hard 项的真 Simulator 证据（49 截图 + 2 录屏 + 构建/测试日志 + 沙盒 store 快照 + Photos 读回，SHA256 回归全量校验 0 失败）。
- 构建可交付：headless xcodebuild BUILD SUCCEEDED + 20/20 单测 0 失败；XcodeGen `project.yml` 生成 `TourWise.xcodeproj`，iOS 17+ / iPhone only。
- 功能全实现：14 条 route 全落地；核心闭环（新建 → walkthrough 打分/拍照 → Finish → Compare 2–5 套 → Make Verdict → Save to Photos 扣 credit）端到端运行时走通；9 内置指标 + 多权重 Profile（Σ=100 阻存）+ 归一化加权排名公式。
- 合规就位：yanran consumable IAP（473900/473901，首启 seed 100，无 Restore/订阅）；ATT/麦克风缺席证明集齐全；相机/读相册/写相册 JIT + denied 三继续项；两独立 HTTPS 法律 WebView；本地 JSON + Delete All Data 二次确认。
- 视觉系统："Evidence board on warm paper" 全表面一致，5 个 motion moment 带 Reduce Motion 等价，3 个 mandatory image slots 已接线。
- Bug 总线终态：open 0 / merged 0 / verified 5（3 条 L0 误报核销，2 条文档缺口经 patch 修复转 verified）。
- 交付物即产品仓 HEAD `ba0bdb5`（= 已测 commit `504e1bf` 产品源码 + 仅 run-context 发布文件，源码零变更）。

## Links

- report_html: n/a（未生成；MAP 即操作者报告，如需 HTML 可用 `human-delivery-report` 从本 run 目录派生）
- commits: `ac95bbe` feat rough_app attempt-1 · `504e1bf` 已测交付基线 · `208f740`/`ba0bdb5` run-context 发布（产品源码无变更）
- bug bus: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/qa/bugs.jsonl

## Gaps

| gap_id | severity | note |
|--------|----------|------|
| g2 | low | 字体为固定点级 token，不响应 Dynamic Type；AX3 下不裁切不重叠（字面成立），建议后续改相对 text style；不阻塞放行 |
| g3 | low | 环境限制备案：Simulator 无相机硬件（真 denied 仅源码佐证）、simctl 挂不了 .storekit（购买注入不可达）、320×568 设备不存在以 iPhone SE 2nd gen 375×667 替代 |
