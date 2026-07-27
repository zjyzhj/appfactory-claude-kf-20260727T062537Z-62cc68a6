# Checklist · TourWise

- Standard: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-2/MAP.md
- Policy: agents/FinalGateAgent/direct-repo-required-checks.json
  - required_check_policy_version: 2.12.0
  - required_check_policy_sha256: c2ebf538a5c0c4e1385ee84bb1fe229ccbd1c30ea66aba4b24f3bd751babbcda
- Data contracts:
  - agents/FinalGateAgent/data-contracts/iap/yanran.json sha256: b6b737cedfcec27d9104ffc4fb60e2c23479a7c2bcf6dec6bf14983959e60790
- Evidence classes: agents/FinalGateAgent/check-evidence-classes.json
- Acceptance policy (run binding): runtime_verification_required · simulator_runtime REQUIRED · evidence_skill ios_runtime_acceptance · policy sha256 cb56b5d7daa90d2173a7d2eb10d6b10329b123f1b668f599ee933660c911651e
- Checks: ./checks.md
- Status: ready

## 与 attempt-1 的差异

- attempt-1 清单 ## Gaps 的 g1 已闭环:pm_docs attempt-2 将 6 处 IAP 文案(Commerce card、F8、ACC-F8-IAP、ExportCreditLedger、product 商业化段、paywall 行)对齐 yanran 目录(473900/110 credits $0.99、473901/210 credits $1.99、initial_balance=100),旧文案 "10/30 两档 / seed 3" 已全量移除(本次逐文件 grep 复核,无残留)。
- refine 未引入新冲突:产品方向、IA、权限、设计、ACC 其余行不变;policy v2.12.0 与 yanran hash 与 attempt-1 完全一致。**全单(A1–A17 + B1–B11)仍然有效**,仅 checks.md 文头 PM 标准指向 attempt-2、IAP reconcile 注记改为已闭环。
- Gaps 表清空,无遗留 refine 路由项。

## 清单概览

- A 组:policy 必查 17 项(v2.12.0 全量,稳定 check_id 与 policy 语义逐字绑定,`functional_completeness_final_review` 排最后)。
- B 组:产品专项 11 项(PM ACC 落锤:walkthrough 生命周期、加权公式、指标体系、级联删除、verdict 导出、四类图片槽、本地隐私面、headless 构建)。
- 分支裁定:Microphone 与 ATT 走**缺席分支**(能力图无音频工作流、无分析/追踪,PM 已声明缺席),均挂硬缺席证明集(无 usage key、无 API 引用、PrivacyInfo 一致、专项缺席测试、运行时零意外弹窗)。IAP 不可分支:yanran consumable balance 目录为唯一模型。
- IAP:PM 文案与 hash 绑定 yanran 目录已完全一致(attempt-2),清单 A9 以目录为唯一标准,无双标准。
- AI:remote_ai=no,无 remote AI 检查、无凭证封装检查;禁止出现发明的 relay client / trial gate。
- 运行时硬要求:本 run 为 runtime_verification_required,A1/A3/A4/A5/A6/A7/A8/A11/A12/A13/A14/A15、B1/B5 等 runtime_hard id 在 verification 阶段必须携带 ios_runtime_acceptance Simulator 证据(install/launch/screenshot/readback,hash 绑定),否则 block:`runtime_mode_missing_runtime_evidence:<check_id>`。相机 granted 路径须经确定性 capture substitute seam 用合成媒体走通。

## Gaps

(无)
