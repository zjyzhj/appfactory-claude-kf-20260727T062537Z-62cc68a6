# Product · TourWise — Home Viewing Scorecard

## 一句话产品
TourWise 是本地优先、零账号的 iPhone 看房决策助手：看房现场按房间拍证据照并打分，回家用可调权重横向对比所有看过的房，导出一张结论卡说服自己与家人。不做房源搜索、不做账号云同步、不做 AI。

- category_skeleton: `decision_assistant`(compare options → recommend → choose;非 log_record_archive)
- ia_shape: `tab_3_to_5`(4 个 task-distinct 主 tab:Viewings / Compare / Criteria / Settings)
- remote_ai: **no**(工厂 relay key 当前不可用；产品本身也不需要 AI 完成核心闭环)
- UI 语言:en-US(本文档记录 en-US copy 意图)

## 用户与场景
正在密集看房(1–2 周看 5–15 套)的租房者与首套购房者，单人或与伴侣共同决策。事件型高价值使用：单次决策牵涉数千到数十万美元，使用频次低但每次会话密度极高。典型时刻：一天连看 4 套，第 4 套出来时第 1 套的厨房已经想不起来。

## 核心闭环(core loop)
1. New Viewing → 录入地址/租金等基础信息(30 秒内可开始打分)。
2. Walkthrough 引导流：按房间(Kitchen / Living / Bedroom / Bath / Building / Outdoor)逐项打分(1–5)、拍证据照、一句话备注；可跳过任何项。
3. 回到 Viewings：每套房有完成度与均分；标记 toured / shortlist / rejected。
4. Compare：选 2–5 套 shortlist，按当前 WeightProfile 加权排序，逐指标并排对比。
5. Verdict：生成结论卡(排名 + 关键证据照 + 权重依据),导出到相册或系统分享(消耗 1 枚 Export Credit)。
6. 下周末再看新房 → 加入对比，排序自动更新。

## 差异化(wedge)
唯一把「现场证据 → 加权排序 → 可分享结论」串成闭环的本地零账号产品。证据照绑定房间而非相册散片；权重模型是一等产品对象而非写死 checklist;Verdict 卡是决策的交付物。

## 硬边界
- 不做房源搜索/聚合(那是 Zillow/Trulia 的战场，network moat)。
- 不做账号、云同步、多人实时协作(v0 单设备;Verdict 卡导出即协作接口)。
- 不做 AI 打分/AI 建议(remote_ai: no,见 ai-and-privacy.md)。
- 不做房东/物业巡检视角(RentCheck 的市场)。
- 不做完整搬家管理(搬家清单、utilities 迁移是 v1+ 候选)。

## 市场供给与立场(proceed_narrow_wedge 必填)
竞争带:med collision / red heat(red 来自 L0 弱匹配门户，直接 job 近乎无人服务)。

- 不与 HotPads(trackId 345957475,https://apps.apple.com/us/app/hotpads-apartment-rentals/id345957475)、Zumper(678683201,https://apps.apple.com/us/app/zumper-apartment-finder/id678683201)竞争：它们止步于找房与约看,saved homes 无逐房间评分与权重比较——我们不碰房源发现。
- 不与 RentCheck(1134017691,https://apps.apple.com/us/app/rentcheck/id1134017691)竞争：房东巡检工作流，非租客决策比较。
- 直接同形者 Home Hunter - Smart Checklist(6754038639,https://apps.apple.com/us/app/home-hunter-smart-checklist/id6754038639)与 Home viewing - house checklist(6774289434,https://apps.apple.com/us/app/home-viewing-house-checklist/id6774289434)均 0 评分、无迭代证据；我们的区别 = photo-evidence 绑定 + 权重模型 + verdict 导出闭环，三者缺一即塌缩为 clone(non-goals 已镜像)。
- 只竞争面：tour 之后的 30 分钟决策窗口。

## 商业化(详见 ai-and-privacy.md Commerce card)
StoreKit consumable(yanran balance catalog):Export Credit。核心打分/对比永久免费；导出 Verdict 卡消耗 1 枚；新用户赠 3 枚；售 10/30 枚包。无订阅、无解锁制、无 Restore Purchases 入口(consumable 语义)。
