# Data Model · TourWise

全本地持久化(SwiftData 或等价本地存储);无网络、无账号。照片以本地文件 + 相对路径引用存储(禁止绝对路径),资产 id 不变量:删除 Viewing 级联删除其 RoomNote 与本地照片文件。

## 实体

### Viewing
| field | type | notes |
|-------|------|-------|
| id | UUID | pk |
| title | String | 默认 "123 Main St, Apt 4B" 由 address 派生,可改 |
| address | String | 必填(可短) |
| rentCents | Int? | 可选;展示 "$1,850/mo" |
| beds / baths | Int? / Double? | 可选 |
| status | enum: draft/toured/shortlisted/rejected | 见状态机 |
| visitedAt | Date | 默认 now |
| generalNotes | String | 可空 |
| createdAt / updatedAt | Date | |

### RoomNote(房间评估,绑定证据)
| field | type | notes |
|-------|------|-------|
| id | UUID | pk |
| viewingId | UUID | fk → Viewing,级联删 |
| roomType | enum: kitchen/living/bedroom/bath/building/outdoor/custom(String) | 步进顺序由房间列表决定 |
| criterionScores | [UUID: Int] | criterionId → 1...5;只存已打分项 |
| note | String | 一句话备注,可空 |
| photoRelativePaths | [String] | 0..n,本地相对路径 |
| state | enum: pending/scored/skipped | walkthrough 步进用 |

### Criterion(评分指标)
| field | type | notes |
|-------|------|-------|
| id | UUID | pk |
| name | String | 唯一(en-US) |
| sfSymbol | String | 展示图标 |
| isBuiltIn | Bool | 内置不可删,可停用 |
| isEnabled | Bool | 停用后不进 walkthrough/对比 |
| sortOrder | Int | |

内置指标(seed):Natural Light / Noise / Space & Storage / Condition / Kitchen / Bathroom / Location & Commute / Building & Safety / Price Fit。

### WeightProfile(权重方案,一等对象)
| field | type | notes |
|-------|------|-------|
| id | UUID | pk |
| name | String | 如 "Commute-first" |
| weights | [UUID: Int] | criterionId → 0...100,校验 Σ=100 |
| isActive | Bool | 全局恰一个 active |
| updatedAt | Date | |

seed 一个 "Balanced" 默认方案(9 指标均分到和 100)。

### ExportCreditLedger(consumable 余额)
| field | type | notes |
|-------|------|-------|
| balance | Int | ≥0;初始 100(首启 seed,yanran initial_balance=100) |
| transactions | [CreditTxn] | 追加式:grant(seed,+100)/purchase(productId ∈ {473900:+110, 473901:+210})/spend(verdictExport,-1) |
| updatedAt | Date | |

### ExportRecord
| field | type | notes |
|-------|------|-------|
| id | UUID | pk |
| viewingIds | [UUID] | 参与对比的集合快照 |
| weightProfileId | UUID | 导出时使用的方案 |
| verdictPhotoRelativePath | String? | 若存相册成功则记录渲染卡本地副本 |
| createdAt | Date | |

## 关系与不变量
- Viewing 1—n RoomNote;RoomNote.photoRelativePaths 指向 app 沙盒 `Photos/<viewingId>/<uuid>.jpg`。
- 加权得分 = Σ(score[c] × weight[c]) / Σ(weight[c] over 已打分且启用指标);缺分指标按"已打分归一化",不惩罚未打分房间——compare_board 对缺分单元格显示 "—"。
- 删除 WeightProfile:不允许删 active/最后一个;引用了它的 ExportRecord 保留快照不级联。
- 余额不变量:导出成功才 spend;StoreKit 交易 finish 前不落 purchase 入账;spend 与渲染必须同事务(渲染失败退款)。
