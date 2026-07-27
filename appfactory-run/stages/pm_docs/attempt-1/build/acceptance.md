# Acceptance · TourWise

可静默源码验证的观测条件为主;UI copy 为 en-US 字面或近等价。

## 核心功能 ACC
| acc_id | route | observable pass condition |
|--------|-------|---------------------------|
| ACC-F1-CREATE | tab_viewings / viewing_edit | 新建 Viewing(仅地址必填)保存后出现在列表,status=draft;30 秒内可完成 |
| ACC-F1-DELETE | viewing_detail | 删除有确认弹窗;确认后该 Viewing 及其 RoomNote、本地照片文件级联删除 |
| ACC-F2-WALKTHROUGH | capture_walkthrough | 房间步进可打分 1–5/备注/跳过/乱序跳转;Finish 后 status=toured;中断后 "Resume Walkthrough" 恢复到原房间原进度 |
| ACC-F3-PHOTO | room_capture | 相机拍摄与相册选取的照片写入 RoomNote.photoRelativePaths 并在 detail_photo_strip 可见;使用相对路径持久化 |
| ACC-F3-DENIED | room_capture | 相机 denied 时展示 Choose Photo / Add without a photo / Retry Camera 三继续项;全源码无 "Open Settings"、openSettingsURLString 调用 |
| ACC-F4-CRITERIA | tab_criteria | 9 内置指标 seeded;可新建自定义指标并即时进入 walkthrough;内置不可删;停用指标不再出现在打分与对比 |
| ACC-F5-WEIGHTS | weight_editor | Σ≠100 阻止保存并提示差值;切换 active profile 后 compare 排名即时重排 |
| ACC-F6-COMPARE | compare_board | 2–5 套 shortlist 并排;缺分单元格显示 "—";归一化加权分计算与 data-model 公式一致 |
| ACC-F7-VERDICT | verdict_card | 结论卡含排名 #1、≥1 张证据照(无照片时色块降级)、权重依据;Save to Photos 成功后扣 1 credit;写权限 denied 时 Share 可用 |
| ACC-F8-IAP | paywall | 10/30 两档 consumable;购买成功余额增加且 transactions 有 purchase 记录;失败 toast 不改余额;无 Restore/订阅/解锁文案 |
| ACC-NAV | (shell) | TabView 4 tab(Viewings/Compare/Criteria/Settings),tab 切换保留各 tab 内选中与进行中状态 |
| ACC-KB | viewing_edit 等 | 所有输入框 return/失焦收起键盘 |

## 图片槽 ACC(required)
| acc_id | route | observable pass condition |
|--------|-------|---------------------------|
| ACC-VIS-ICON | n/a | AppIcon imageset 存在于 Asset Catalog 且被 Info/构建引用 |
| ACC-VIS-HERO | tab_viewings | home_hero 槽视图存在于首页源码;资产缺失时渐变 + SF Symbol 兜底可见 |
| ACC-VIS-EMPTY | tab_viewings | 列表为空时 viewings_empty_illustration 槽可见(含 fallback 路径) |
| ACC-VIS-MEDIA | room_capture / viewing_detail / verdict_card | room_photo_slot 采集路径与 detail_photo_strip 展示路径存在;空照片状态有声明的兜底 |

## 动效 ACC(required)
| acc_id | route | observable pass condition |
|--------|-------|---------------------------|
| ACC-MOT-ENTRY | tab_viewings | mot_entry_settle 实现:首帧 hero 落位 + 列表 stagger(或 Reduce Motion 静态等价) |
| ACC-MOT-COMMIT | room_capture / tab_compare | mot_commit_photo 飞入落板 + medium haptic;mot_rank_regrow 条柱重生长 |
| ACC-MOT-SUCCESS | verdict_card | mot_success_verdict 发牌式入场 + #1 徽标延迟弹入;导出成功 success haptic |
| ACC-MOT-EMPTY | tab_viewings | mot_empty_breathe 呼吸浮动(2.4s ±4pt)一次后静止;非无限循环装饰 |
| ACC-MOT-REDUCE | 全部 | Reduce Motion 开启时五位 moment 全部退化为声明的静态/淡入等价,用户价值不丢 |

## App Review ACC(required)
| acc_id | route | observable pass condition |
|--------|-------|---------------------------|
| ACC-REV-COMPLETE | 全链路 | 建 viewing → walkthrough 打分拍照 → compare → verdict 导出,源码端到端可达;无占位/演示-only 主流程 |
| ACC-REV-MINFUNC | 全链路 | 9 内置指标、多权重方案、证据照、加权排序、渲染导出均真实实现(非 UI 壳);功能集独立交付持久价值 |
| ACC-REV-DIFF | n/a | 产品指纹(域 + decision_assistant 骨架 + 证据/权重/导出三件套)已写入 dedupe 记录,与近包可区分 |
| ACC-REV-PRIVACY | room_capture / verdict_card / privacy | Info.plist 含 Camera / PhotoLibrary / PhotoLibraryAdd 三条产品专属 usage 文案;无未声明权限;privacy 路由从 tab_settings 可达且含 Delete All Data |
| ACC-REV-IAP | paywall / tab_settings | 购买 + 余额账本接线完成;paywall 与 Commerce card 一致(consumable、两档、无 Restore) |
