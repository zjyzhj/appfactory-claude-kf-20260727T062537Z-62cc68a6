# Routes & States · TourWise

命名即代码标识(SwiftUI route id / view 名同形)。en-US copy 为下游实现真源。

## Navigation shell(硬规则:多主任务 + 记录生命周期 → TabView 4 tab)
| tab | route_id | 主任务 | 保留状态 |
|-----|----------|--------|----------|
| Viewings | `tab_viewings` | 管理所有看房记录(建/查/筛) | 选中 filter、进行中的 viewing |
| Compare | `tab_compare` | 选 shortlist → 加权对比 → 出 verdict | 已选 viewing 集合 |
| Criteria | `tab_criteria` | 管理评分指标与权重方案 | 编辑中的 WeightProfile |
| Settings | `tab_settings` | 积分、隐私、导出、关于 | — |

## Route 表
| route_id | 类型 | 入口 | 用途 |
|----------|------|------|------|
| `tab_viewings` | tab root | 启动默认 | Viewing 列表(status 分组:shortlist / toured / rejected),hero 区,空态插画 |
| `viewing_detail` | push | tab_viewings 行 | 单套详情:基本信息、逐房间评估、证据照条、均分、状态切换 |
| `viewing_edit` | sheet | viewing_detail / tab_viewings + | 新建/编辑基础信息(title/address/rent/beds/baths/notes) |
| `capture_walkthrough` | full-screen cover | viewing_detail "Start Walkthrough" / tab_viewings 新建后自动 | 引导多步打分流:房间步进(stepper),每步 score 1–5 + 拍照/选图 + 备注,可跳过/提前结束 |
| `room_capture` | capture_walkthrough 子页 | 步进 | 单房间:camera capture / Photos pick / 跳过,绑定 RoomNote |
| `tab_compare` | tab root | tab | shortlist 选择器 + 加权排名列表(条柱 + 得分) |
| `compare_board` | push | tab_compare(≥2 套) | 并排对比表:行=指标(加权),列=viewing;证据照缩略;权重来源标注 |
| `verdict_card` | sheet | compare_board "Make Verdict" | 结论卡预览(排名 + 3 张关键证据 + 权重依据),Save to Photos / Share,消耗 1 Export Credit |
| `tab_criteria` | tab root | tab | 指标列表(内置 + 自定义),启停、排序 |
| `criterion_edit` | sheet | tab_criteria | 新建/编辑指标(name、icon、说明) |
| `weight_editor` | push | tab_criteria WeightProfile 行 | 权重滑杆组,总和=100% 实时校验;多方案保存/切换 |
| `tab_settings` | tab root | tab | Export Credit 余额与购买入口、隐私入口、数据导出(JSON)、关于 |
| `paywall` | sheet | tab_settings "Buy Credits" / verdict_card 余额不足 | consumable 商品列表(10/30 credits),StoreKit 购买 |
| `privacy` | push | tab_settings | 数据边界说明(全本地)、权限状态信息、删除全部数据 |

## 关键状态机
### Viewing.status
`draft`(建了未走完)→ `toured`(walkthrough 完成或手动标记)→ `shortlisted` → `rejected`;`toured/shortlisted/rejected` 可互转,`draft` 完成 walkthrough 即 `toured`。

### capture_walkthrough 步进
room_queue = 启用的 RoomType 序列;每房间状态:`pending` / `scored` / `skipped`;允许任意顺序跳转、随时 Finish(finish 时 pending 记为 skipped)。中断后从 viewing_detail "Resume Walkthrough" 恢复现场。

### 权限与恢复(硬规则:禁止 Open Settings 文案/跳转;拒绝后保留应用内继续)
| 场景 | 状态 | en-US 行为与文案 |
|------|------|------------------|
| 相机首次 | pre-prompt → system prompt | 仅在 room_capture 点 "Take Photo" 时请求(just-in-time);usage 文案:"TourWise uses the camera to attach evidence photos to the room you are scoring." |
| 相机 denied/restricted | capture_denied | 原位卡片:"Camera is off for TourWise. You can **Choose Photo** from your library, **Add without a photo**, or **Retry Camera**." — 三按钮均在应用内;禁止出现 Settings 字样/跳转 |
| 无相机硬件(模拟器) | camera_unavailable | 自动隐藏 Take Photo,保留 Choose Photo / Add without a photo |
| 相册读 limited/denied | photos_read_limited | 选图器空态:"No photos available. You can **Take Photo** or **Add without a photo**." |
| 相册写 denied(导出) | photos_write_denied | Verdict 卡原位提示:"Saving to Photos is off. You can still **Share** the card." Share 路径不依赖写权限 |
| StoreKit 失败 | purchase_failed | toast:"Purchase didn't complete. Your credits were not changed. **Try Again**" |
| 余额不足 | credits_empty | verdict_card CTA 变 "Get Credits" → paywall;不阻断预览 |

### 全局 en-US 反馈(样例真源)
- 保存 viewing:"Viewing saved." / 删除确认:"Delete this viewing? Its scores and photos will be removed from this iPhone."
- walkthrough 完成:"Walkthrough complete — nice evidence. See how it ranks in Compare."
- compare 不足 2 套:"Shortlist at least 2 viewings to compare."
- verdict 导出成功:"Verdict card saved to Photos." / 分享:系统 share sheet。
- 空态(home):"No viewings yet. Add your first tour and score it room by room."
- 键盘:所有输入框失焦/return 收起键盘。
