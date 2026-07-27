# Design · TourWise

## Visual direction
"Evidence board on warm paper":温暖纸感底色 + 拍立得式证据照卡 + 自信的数据排版。看房是高压决策,界面要像一个可以信赖的桌面证据板——照片是主角,分数与权重是冷静的衬线数字,操作克制。避免 portals 的冷蓝 listing 风,也避免通用 checklist 的灰白工具感。

- Palette(可测量):
  - bg_paper `#F6F1E7`(主背景,全页面完整铺底,非纯白)
  - bg_panel `#FFFFFF`(卡片)
  - ink_primary `#2B2620`
  - accent_brass `#B4762A`(主操作/排名 #1)
  - accent_sage `#6E7F5C`(shortlist/正向)
  - warn_terracotta `#B4503C`(rejected/删除)
  - score_track `#E4DCCB`(条柱轨道)
- Type:系统字体;页面标题 28/34 semibold,分区标题 17/22 semibold,正文 15/20 regular,分数数字 20/24 medium tabular-nums。
- 形状:卡片圆角 14,照片卡圆角 10 带 1pt `#00000010` 描边与 8% 旋转 ≤1.2° 的拍立得微倾斜(仅证据照,不用于数据表)。
- en-US chrome 样例:tab 标题 "Viewings / Compare / Criteria / Settings";主 CTA "Start Walkthrough" / "Make Verdict";空态标题 "No viewings yet"。

## In-app image slots (required)

| slot_id | kind | route_id | component | purpose | asset_or_source | empty_fallback | acc_ids |
|---------|------|----------|-----------|---------|-----------------|----------------|---------|
| `app_icon` | app_icon | n/a | asset catalog AppIcon imageset | 商店/主屏图标:暖纸底 + 黄铜色房屋+星标组合 | pm_visuals 交付 1024px 图标 → Asset Catalog | 不可用(构建必需) | ACC-VIS-ICON |
| `home_hero` | hero | tab_viewings | `Image`(asset `hero_home`)+ 渐变遮罩 + 标题叠层 | 首页顶部品牌/域主视觉(暖调客厅窗台光),确立"证据板"气质 | pm_visuals `slots/home_hero.png` 或等值生成资产 | 纯 `#E9DFC9` 渐变 + SF Symbol `house.fill` | ACC-VIS-HERO |
| `viewings_empty_illustration` | empty_illustration | tab_viewings | `Image`(asset `empty_viewings`)居中空态插画 | 空列表引导:拍立得叠 + 星标,配 "No viewings yet" 与 Add 按钮 | pm_visuals `slots/viewings_empty_illustration.png` | SF Symbol `photo.stack` 56pt accent_brass 40% | ACC-VIS-EMPTY |
| `room_photo_slot` | photo_or_media | room_capture | 照片预览 `Image`(本地文件)/ Photos picker 缩略 | 逐房间证据照采集与预览(用户拍摄/选取),绑定 RoomNote | 用户相机拍摄 / 相册选取(本地相对路径) | 虚线相框 + SF Symbol `camera.fill` + "Add photo evidence" | ACC-VIS-MEDIA |
| `detail_photo_strip` | photo_or_media | viewing_detail | 横向 ScrollView 证据照条(本地 `Image`),点击全屏查看 | 单套房的证据回溯(核心痛点"第 1 套厨房什么样") | RoomNote.photoRelativePaths 本地文件 | 无照时不渲染条,显示 "No photos yet — add during a walkthrough" 文本行 | ACC-VIS-MEDIA |
| `verdict_card_render` | photo_or_media | verdict_card | 渲染视图(排名 + 证据照合成)预览 `Image` | 结论卡预览与导出成品 | 本地渲染(RoomNote 照片合成) | 无证据照时以纯色块 + 分数排版渲染(不阻断导出) | ACC-VIS-MEDIA |
| `criterion_icons` | extra(icon) | tab_criteria | 资产图标集/ SF Symbol 映射 | 指标识别(灯泡=Natural Light、耳朵=Noise…) | 内置资产或 SF Symbol 映射表 | SF Symbol `checklist` | ACC-VIS-ICON |

规则落实:slot 全唯一;`asset_or_source` 均指向 slot 级资产或本地文件,不指向整屏 frame;empty_fallback 全部声明;四类必需 kind(app_icon/hero/empty_illustration/photo_or_media)齐全。

## Motion & interaction language (required)

### Motion thesis
证据落板,结论浮现:每一次打分与拍照都是把一张证据"按"在证据板上,而对比与结论则以克制的生长与落位浮现——动效服务于"从混乱到确定"的决策情绪,而非装饰。

### Shared motion tokens
| token | value | usage |
|-------|-------|-------|
| `dur_settle` | 0.28s spring(response 0.28, damping 0.82) | 证据卡落位、列表插入 |
| `dur_grow` | 0.45s easeOut | 对比条柱、排名变化 |
| `dur_deal` | 0.5s spring(response 0.5, damping 0.75) | Verdict 卡发牌式出现 |
| `haptic_commit` | UIImpactFeedbackGenerator .medium | 打分提交、照片落位 |
| `haptic_verdict` | UINotificationFeedbackGenerator .success | 导出成功 |
| `stagger_room` | 0.06s | walkthrough 房间步进切换 |

### Product moments
| moment_id | route_id | trigger | user_value | motion_behavior | haptic | reduce_motion_equivalent | acc_id |
|-----------|----------|---------|------------|-----------------|--------|--------------------------|--------|
| `mot_entry_settle` | tab_viewings | 冷启动/回首页首帧 | 第一眼确立"证据板"信息重心 | hero 轻微下沉落位(dur_settle),viewing 卡自下而上 0.06s stagger 入场 | 无 | 直接静态呈现终态,无位移 | ACC-MOT-ENTRY |
| `mot_commit_photo` | room_capture | 拍摄/选图确认 | 确认"证据已绑定这个房间" | 照片缩略从预览区飞入房间卡照片位并落板(dur_settle + 1.2° 微倾斜),房间卡短暂抬升 2pt 回弹 | haptic_commit | 照片即时静态落位 + 60ms 透明度淡入 | ACC-MOT-COMMIT |
| `mot_success_verdict` | verdict_card | "Make Verdict" 点击 | 决策交付的仪式感 | 结论卡以发牌式从上沿滑入并轻微回正(dur_deal),#1 排名徽标随后 0.15s 弹入 | haptic_verdict(导出成功时) | 卡片无位移直接呈现,徽标以透明度淡入 | ACC-MOT-SUCCESS |
| `mot_empty_breathe` | tab_viewings | 列表为空展示空态 | 空态不"死",引导首个动作 | 空态插画 2.4s 周期 ±4pt 呼吸浮动,Add 按钮同步 5% 亮度脉动一次后静止 | 无 | 静态插画 + 静态按钮 | ACC-MOT-EMPTY |
| `mot_rank_regrow` | tab_compare / compare_board | 切换 active WeightProfile | 权重变化"看得见"地影响结论 | 条柱以 dur_grow 重生长到新值,排名位移用 matchedGeometry 换位 | 无 | 数值即时更新,条柱无动画 | ACC-MOT-COMMIT |

### Forbidden
- 禁止任何自动轮播/无限循环装饰动画(证据板是冷静工具)。
- 禁止页面级粒子/ confetti(包括导出成功;仪式感由发牌动效承担)。
- 禁止拍照后的强制全屏"欣赏"转场打断 walkthrough 节奏。
- 禁止把 rank 变化做成闪烁/颜色爆闪。

## Visual frames(pm_visuals 整屏参考,≤6)
| frame_id | route_id | purpose | layout skeleton | density | avoid |
|----------|----------|---------|-----------------|---------|-------|
| `frame_home` | tab_viewings | 首页:hero + viewing 卡列表 | 顶 hero(30% 屏高)+ 分组列表卡 + tab bar | mid | 冷蓝 listing 风 |
| `frame_home_empty` | tab_viewings | 空态 | 居中插画 + 标题 + 单 CTA | low | 纯文字空态 |
| `frame_walkthrough` | room_capture | 打分采集 | 顶部房间步进条 + 照片位(40%)+ 1–5 分排 + 备注行 | mid | 表单堆叠 |
| `frame_compare` | compare_board | 并排对比 | 左指标列 + 横向滑动 viewing 列 + 顶排名条 | high | 拥挤小字 |
| `frame_verdict` | verdict_card | 结论卡 | 卡片居中(60%)+ 底部 Save/Share 双按钮 | mid | 系统弹窗感 |
| `frame_paywall` | paywall | 积分购买 | 余额卡 + 两档商品卡 + 说明 | low | 订阅话术 |

pm_visuals 可按 slot_id 额外产出 `slots/<slot_id>.png` 嵌入位图;slot_id 保持文件名安全。整屏 frame 仅作布局参考,不接进 `asset_or_source`。

## Accessibility
- Dynamic Type 到 AX3;分数/权重数字 tabular-nums;对比表横滑列头固定。
- 所有照片位有 accessibilityLabel("Kitchen evidence photo 1 of 3");打分控件可读值("4 of 5 for Natural Light")。
- 对比表颜色不单独承载排名(同时给 #1/#2 文本徽标);Reduce Motion 见上表逐条等价。
- 最小布局 320×568 不溢出:walkthrough 打分排改为纵向 5 行;对比表列宽 ≥132pt 横滑。
