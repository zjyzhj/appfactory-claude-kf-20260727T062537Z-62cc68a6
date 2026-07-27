# TourWise — package map

Status: ready

> attempt-2 = checklist g1(product_shape)refine:仅修订 IAP 文案,使其与 hash 绑定 yanran 目录(agents/FinalGateAgent/data-contracts/iap/yanran.json)完全一致。产品方向、IA、权限、设计均不变。
>
> 改动清单(6 处):
> 1. build/ai-and-privacy.md Commerce card —— seed 3 → 首启 seed 100(initial_balance=100);价格档 10/30 credits → 473900(110 credits,$0.99)/ 473901(210 credits,$1.99)
> 2. build/features.md F8 —— 同上两档 product_id + 首启 seed 100
> 3. build/acceptance.md ACC-F8-IAP —— 同上两档 + 首启余额 100 可观测条件
> 4. build/data-model.md ExportCreditLedger —— balance 初始 3 → 100;transactions 标注 grant(+100)/purchase(473900:+110, 473901:+210)/spend(-1)
> 5. build/product.md 商业化段 —— 同口径(赠 100 枚;两档 product_id)
> 6. build/routes-and-states.md paywall 行 —— 商品列表改 473900/473901
>
> 不变项:导出成功才扣 1(spend 与渲染同事务,渲染失败同事务退款)、无 Restore、无订阅/解锁 —— 原文已符合,未改。

TourWise 是本地优先、零账号的 iPhone 看房决策助手:看房现场按房间拍证据照并打分,用可调权重横向对比所有看过的房,导出 Verdict 结论卡。category_skeleton = decision_assistant;remote_ai = no;IAP = consumable Export Credit(yanran)。

## Package reading order

1. [Product definition](build/product.md)
2. [Routes and states](build/routes-and-states.md)
3. [Data model](build/data-model.md)
4. [Features](build/features.md)
5. [AI, privacy, and commerce](build/ai-and-privacy.md)
6. [Design, image slots, and motion](build/design.md)
7. [Acceptance criteria](build/acceptance.md)
8. [Non-goals](build/non-goals.md)

## Package doc index

- 产品定位、核心闭环、category_skeleton/ia_shape、§市场供给与立场(proceed_narrow_wedge 结论):[build/product.md](build/product.md)
- 4-tab 路由契约、状态机、权限拒绝应用内恢复、en-US copy 真源:[build/routes-and-states.md](build/routes-and-states.md)
- 本地实体(Viewing/RoomNote/Criterion/WeightProfile/CreditLedger)、关系与不变量:[build/data-model.md](build/data-model.md)
- F1–F8 能力图与功能-媒体扩张:[build/features.md](build/features.md)
- AI implementation card(remote_ai: no)、Commerce card(consumable Export Credit)、隐私边界、App Review risk card:[build/ai-and-privacy.md](build/ai-and-privacy.md)
- 视觉方向、In-app image slots(四类必需)、Motion & interaction language、pm_visuals frames:[build/design.md](build/design.md)
- ACC 全表(核心功能 + ACC-VIS-* + ACC-MOT-* + ACC-REV-*):[build/acceptance.md](build/acceptance.md)
- v0 明确不做与 Top-N 不竞争面:[build/non-goals.md](build/non-goals.md)
