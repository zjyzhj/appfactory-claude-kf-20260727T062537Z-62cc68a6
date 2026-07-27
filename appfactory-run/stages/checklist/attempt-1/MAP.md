# Checklist · TourWise

- Standard: /Volumes/zjySD/claude-app-factory/runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-1/MAP.md
- Policy: agents/FinalGateAgent/direct-repo-required-checks.json
  - required_check_policy_version: 2.12.0
  - required_check_policy_sha256: c2ebf538a5c0c4e1385ee84bb1fe229ccbd1c30ea66aba4b24f3bd751babbcda
- Data contracts:
  - agents/FinalGateAgent/data-contracts/iap/yanran.json sha256: b6b737cedfcec27d9104ffc4fb60e2c23479a7c2bcf6dec6bf14983959e60790
- Evidence classes: agents/FinalGateAgent/check-evidence-classes.json
- Acceptance policy (run binding): runtime_verification_required · simulator_runtime REQUIRED · evidence_skill ios_runtime_acceptance · policy sha256 cb56b5d7daa90d2173a7d2eb10d6b10329b123f1b668f599ee933660c911651e
- Checks: ./checks.md
- Status: ready

## 清单概览

- A 组:policy 必查 17 项(v2.12.0 全量,稳定 check_id 与 policy 语义逐字绑定,`functional_completeness_final_review` 排最后)。
- B 组:产品专项 11 项(PM ACC 落锤:walkthrough 生命周期、加权公式、指标体系、级联删除、verdict 导出、四类图片槽、本地隐私面、headless 构建)。
- 分支裁定:Microphone 与 ATT 走**缺席分支**(能力图无音频工作流、无分析/追踪,PM 已声明缺席),均挂硬缺席证明集(无 usage key、无 API 引用、PrivacyInfo 一致、专项缺席测试、运行时零意外弹窗)。IAP 不可分支:yanran consumable balance 目录为唯一模型。
- IAP reconcile:PM 文案 "10/30 credits 两档 / 初始 seed 3" 与 hash 绑定 yanran 目录(最低档 110/210、initial_balance=100)冲突,清单以目录为准钉死;PM 文案修订见 ## Gaps。
- AI:remote_ai=no,无 remote AI 检查、无凭证封装检查;禁止出现发明的 relay client / trial gate。
- 运行时硬要求:本 run 为 runtime_verification_required,A1/A3/A4/A5/A6/A7/A8/A11/A12/A13/A14/A15、B1/B5 等 runtime_hard id 在 verification 阶段必须携带 ios_runtime_acceptance Simulator 证据(install/launch/screenshot/readback,hash 绑定),否则 block:`runtime_mode_missing_runtime_evidence:<check_id>`。相机 granted 路径须经确定性 capture substitute seam 用合成媒体走通。

## Gaps

| gap_id | dimension | severity | evidence | suggested_node | note |
|--------|-----------|----------|----------|----------------|------|
| g1 | G4 | medium | build/ai-and-privacy.md Commerce card;build/features.md F8;build/acceptance.md ACC-F8;build/data-model.md ExportCreditLedger | product_shape | PM 文案写 "10/30 credits 两档、初始 seed 3",与 yanran 目录(product 473900/110、473901/210 起、initial_balance=100)不一致;checklist 已以目录为唯一标准(A9),建议 pm_docs 修订四处文案使文档与数据契约对齐,不影响本清单可执行性 |
