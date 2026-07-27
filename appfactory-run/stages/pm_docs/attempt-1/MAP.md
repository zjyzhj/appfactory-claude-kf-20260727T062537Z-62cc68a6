# TourWise — package map

Status: ready

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
