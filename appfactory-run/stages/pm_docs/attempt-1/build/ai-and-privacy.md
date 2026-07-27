# AI, Privacy & Commerce · TourWise

## AI implementation card
- remote_ai: **no**
- pattern_id: none
- surface: n/a(无 AI 界面)
- primary_cta: n/a
- result_ui: n/a
- access_model: none
- access_detail: no remote AI;所有打分、加权排序、结论卡均为本地确定性计算
- why_not_P1: 不适用(无 remote AI);核心 job 是现场结构化采集 + 加权决策,确定性算法已完整交付,AI 不改善核心闭环
- near_neighbor_diff: 邻近包 Waitwise 用 remote AI P8 coach_prompt;本包 remote_ai=no,连 AI surface 都不存在,呈现零重叠。组合维度上本包把批次推向 no-remote 一侧(目标 ~50%)。另:工厂 relay key 当前不可用(doctor 已知搁置),no-remote 也是生产约束下的正确选择

## Commerce card
- iap: required (yanran)
- money_value: **Export Credit** —— 导出 Verdict 结论卡(渲染图,Save to Photos / Share)每次消耗 1 枚。用户为"把决策交付给自己/家人"的交付物付费;打分、权重、对比等核心能力永久免费
- paywall_hook: `tab_settings` "Buy Credits" 行;`verdict_card` 余额为 0 时 CTA "Get Credits"
- entitlement_model: consumable(yanran balance catalog;任何非消耗型/订阅/买断模型即政策违规)
- restore: no(consumable 不提供 Restore Purchases 入口)
- why_not_factory_default: 无 AI 故不存在 "1 free AI then AI Unlock";付费对象是非 AI 的导出交付物,新用户 seed 3 枚(产品自定,非全局 trial=1 教条);价格档 10 / 30 credits 两档

## Privacy
- 数据边界:全部数据(Viewing / RoomNote / 照片 / 权重 / 积分账本)仅存设备本地;无账号、无分析 SDK、无追踪、无第三方网络调用(StoreKit 除外)。
- 权限清单(最小且产品专属):
  - Camera(room_capture just-in-time;usage:"TourWise uses the camera to attach evidence photos to the room you are scoring.")
  - Photo Library Read(room_capture 选已有证据照;usage:"TourWise lets you attach existing photos from a viewing to its room scores.")
  - Photo Library Add/Write(verdict_card 保存结论卡;usage:"TourWise saves your verdict card to Photos so you can share it with family.")
  - 拒绝/受限均在应用内继续(见 routes-and-states.md 权限表;禁止 Settings 跳转)。
  - Microphone:**声明缺席** —— 能力图无任何音频工作流(视频录制、语音备注均不做)。
  - ATT:**声明缺席** —— 无广告、无追踪、无数据出设备,不弹 ATT。
- `tab_settings → privacy` 路由可达:展示上述边界、"Delete All Data" 二次确认。
- 法律:隐私政策与用户协议入口(legal webviews)在 tab_settings。

## App Review risk card (required)

| guideline | risk_for_this_product | mitigation_in_package | proving_finalgate_check | acc_id |
|-----------|-----------------------|-----------------------|--------------------------|--------|
| 2.1 App Completeness | 看房决策是事件型低频场景,审核员可能误判为"半成清单工具" | 核心闭环端到端可演示:建 viewing → walkthrough 打分拍照 → 权重对比 → verdict 导出,无占位流程;空态/拒绝态/缺分态全部有实现 | product_maturity:core_value_and_feature_completeness | ACC-REV-COMPLETE |
| 4.2 Minimum Functionality | 窄场景(只覆盖"看房后决策")是否足够是真实 App | 窄而完整:4 tab 能力图(记录/指标权重/对比/交付),9 内置指标 + 自定义 + 多权重方案 + 证据照 + 加权排序 + 渲染导出,独立交付持久价值;非 wrapper/demo | product_maturity:feature_expansion | ACC-REV-MINFUNC |
| 4.3 Spam / Repeat | 与工厂既有包及商店 checklist 类相似度 | dedupe 全局库无碰撞;与邻近包 Waitwise(game_skill 麻将 trainer)在品类骨架(decision_assistant)、域、交互上全不同;与 0 评分同形者的区别=证据照绑定+权重模型+导出闭环(product.md §市场供给与立场) | (dedupe record; no check_id) | ACC-REV-DIFF |
| 5.1.1 Data Minimization | 相机/相册双权限是否过度 | 三权限均 just-in-time 且绑定具体任务(房间证据拍/选、结论卡保存);拒绝后应用内继续;无麦克风/ATT/定位;数据不出设备,privacy 路由可自查可全删 | ios_delivery:camera_permission, ios_delivery:photo_library_read_write_permission | ACC-REV-PRIVACY |
| 3.1.1 In-App Purchase | 数字交付物(导出额度)必须走 IAP 且模型合规 | Export Credit 为 StoreKit consumable(yanran balance catalog),不碰实物/外链支付;无订阅、无解锁、无 Restore 误标;购买失败友好提示 | ios_delivery:consumable_iap | ACC-REV-IAP |

### Review notes
- 审核演示路径建议固定为:onboarding 免登录直接进 home → 新建 viewing → walkthrough 打两间房(含一张相机照)→ Compare 选两套 → Make Verdict → Save to Photos(消耗 1 credit)→ Settings 展示余额变化。全程 ≤3 分钟、无网络依赖。
- 元数据避免 "find apartments / listings / MLS" 等词,定位词:"tour scorecard, compare rentals, viewing checklist, decision helper"。
- 4.2 论证要点已写入本卡;若后续 checklist 反馈 v0 偏薄,按 Graph refine 在 build/* 内加厚(候选:move-in cost sheet),不弱化本卡。
