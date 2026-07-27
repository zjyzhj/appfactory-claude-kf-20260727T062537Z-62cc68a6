# rough_app · TourWise

Status: ready

TourWise 是本地优先、零账号的 iPhone 看房决策助手:看房现场按房间拍证据照并打分,用可调权重横向对比所有看过的房,导出 Verdict 结论卡。remote_ai = no;IAP = yanran consumable Export Credit(473900/473901,首启 seed 100)。

## Product repo

- Path: `runs/kf-20260727T062537Z-62cc68a6/product`(XcodeGen `project.yml` → `TourWise.xcodeproj`;Xcode 26.4.1,iOS 17+ target,iPhone only)
- Git: `main` @ commit `feat(tourwise): rough_app attempt-1`,pushed to <https://github.com/zjyzhj/appfactory-claude-kf-20260727T062537Z-62cc68a6>(org `wangrenzhu-ola` 无创建权限,落到已认证账号;repo 名与 job 一致)
- Stack: Swift 5 / SwiftUI;文件 JSON 持久化(LocalStore)+ 沙盒 `Photos/<viewingId>/` 相对路径照片;StoreKit 2;无 SwiftData/无三方依赖

## What shipped(S0–S7)

- **14 routes 全实现**(routes-and-states.md):`tab_viewings`(hero + status 分组 + 搜索 + 空态)、`viewing_detail`(证据照条/房间卡/状态切换/级联删除)、`viewing_edit`、`capture_walkthrough` + `room_capture`(步进/乱序/跳过/中断恢复/finish 汇总)、`tab_compare`(2–5 shortlist + 加权排名)、`compare_board`(固定指标列 + 横滑 viewing 列 ≥140pt + 缺分 "—")、`verdict_card`(渲染预览 + Save/Share)、`tab_criteria`、`criterion_edit`、`weight_editor`(Σ=100 实时校验阻存 + 差值提示)、`tab_settings`、`paywall`、`privacy`。
- **核心闭环 A1 路径可达**:新建(仅地址)→ 自动进 walkthrough → 打分/拍照 → Finish=toured → Compare 选 2 套 → Make Verdict → Save to Photos 扣 1 credit。
- **F2/B1 walkthrough 生命周期**:6 房间队列,任意跳转,Resume 恢复原房间,finish 时 pending→skipped,汇总展示 scored/skipped。
- **F4/B3 指标体系**:9 内置指标 seeded(稳定 UUID 幂等),内置不可删可停用,自定义即时进打分/对比。
- **F5/B2 权重**:多 WeightProfile,"Balanced" seed Σ=100;Σ≠100 阻存并提示差值("Total is 90% — add 10 to save");切 active 即时重排。
- **F6/B2 公式**:Σ(score×weight)/Σ(weight over 已打分且启用指标);缺分不造 0;单测覆盖归一化/停用剔除/换权重重排/2–5 边界。
- **F7/B5 verdict**:UIKit 确定性渲染 2160×2700 PNG(#1 徽标、大分数、≤3 证据照拍立得、runner-up 条柱、权重依据+日期);无照片纯色块降级不阻断;Save/Share 成功才扣 1;渲染失败同事务退款;余额 0 CTA 变 Get Credits 不阻断预览。
- **F8/A9 IAP**:StoreKit 2 consumable,目录字面 `473900`(+110)/`473901`(+210);首启 grant(+100);验证后入账、finish 前落账、按交易 id 幂等;失败 toast "Purchase didn't complete. Your credits were not changed. Try Again" 不动余额;**无 Restore/订阅/解锁**;`TourWise.storekit` 随 scheme 供 Simulator 购买测试。
- **权限边界(A12/A13/B10)**:三条 PM 字面 usage 文案;相机/读相册/写相册全 JIT;denied 原位三继续项(Choose Photo / Add without a photo / Retry Camera);**全源码无 Open Settings/跳转**;合成捕获 seam(`-syntheticCapture` 或 `TOURWISE_SYNTHETIC_CAPTURE=1`)供 Simulator 走通 granted 捕获;privacy 路由展示边界+权限状态+Delete All Data 二次确认。
- **缺席证明集(A14/A15)**:无 NSMicrophoneUsageDescription/NSUserTrackingUsageDescription、无 AVAudio*/ATTrackingManager/AdSupport 引用、PrivacyInfo NSPrivacyTracking=false、专项单测、grep CLEAN(见 MAP.progress.md)。
- **A10 法律**:Settings 内两个独立 HTTPS WebView(tourwise.app/privacy 与 /terms 模板 URL),加载失败友好态 + Retry。
- **A16 键盘**:所有输入面 scrollDismissesKeyboard + onSubmit 收起,内容保留。

## Visual system + motion(A6/A7)

- "Evidence board on warm paper" 全表面一致:bg_paper `#F6F1E7` 铺底、accent_brass `#B4762A`、卡片圆角 14、证据照圆角 10 + 1pt 描边 + ≤1.2° 拍立得倾斜(仅证据照)、分数 tabular-nums、排名 #1/#2 文本徽标(非仅颜色)。
- 5 个 moment 全实现并带 Reduce Motion 等价:`mot_entry_settle`(hero 落位 + 列表 0.06s stagger)、`mot_commit_photo`(照片飞入落板 + medium haptic + 房间卡 2pt 抬升回弹)、`mot_success_verdict`(dur_deal 发牌入场 + #1 徽标 0.15s 延迟弹入 + success haptic)、`mot_empty_breathe`(2.4s ±4pt 呼吸一次后静止 + CTA 5% 亮度脉动一次,非循环)、`mot_rank_regrow`(dur_grow 条柱重生长 + 行换位)。无轮播/粒子/confetti/rank 闪爆。

## Upstream visuals

- pm_visuals status: validated(attempt-2)
- frames_read:

  | frame_id | path | used_for |
  |----------|------|----------|
  | frame_home | stages/pm_visuals/attempt-2/frames/frame_home.png | tab_viewings hero 比例(30%)+ 卡密度 + 分组列表 |
  | frame_home_empty | …/frames/frame_home_empty.png | 空态构图 + 4-tab IA 确认 |
  | frame_walkthrough | …/frames/frame_walkthrough.png | room_capture 步进条/照片位/1–5 打分排布局 |
  | frame_compare | …/frames/frame_compare.png | compare_board 固定左列 + 横滑列 + 排名 chips |
  | frame_verdict | …/frames/frame_verdict.png | verdict_card 卡片比例 + Save/Share 双按钮 |
  | frame_paywall | …/frames/frame_paywall.png | paywall 余额卡 + 两档商品卡 + Best value pill |

- frames_ignored: none
- slot_assets_used:

  | slot_id | path | imageset_or_view |
  |---------|------|------------------|
  | app_icon | …/slots/app_icon.png | `Assets.xcassets/AppIcon.appiconset/app_icon.png`(sips 降至 1024×1024) |
  | home_hero | …/slots/home_hero.png | `Assets.xcassets/hero_home.imageset` → `Image("hero_home")` + 渐变遮罩 + 标题叠层(HomeHeroSlot) |
  | viewings_empty_illustration | …/slots/viewings_empty_illustration.png | `Assets.xcassets/empty_viewings.imageset` → `Image("empty_viewings")` 空态槽(ViewingsEmptySlot) |

- slot_assets_ignored: none
- 文本优先冲突说明:frame_compare 底栏画了 5 tab(Home/Viewings/Compare/Shortlist/Profile),与 routes 硬规则 4 tab 冲突 —— 按文本实现 4 tab(Viewings/Compare/Criteria/Settings);frame_walkthrough 顶部品牌条未实现(routes 无此元素,walkthrough 用标准导航栏)。

## Mandatory image slots(design.md 全 7 行)

| slot_id | status | where |
|---------|--------|-------|
| app_icon | done | AppIcon.appiconset(1024,构建引用) |
| home_hero | done | tab_viewings `HomeHeroSlot`,兜底 #E9DFC9 渐变 + house.fill |
| viewings_empty_illustration | done | tab_viewings `ViewingsEmptySlot`,兜底 photo.stack 56pt brass 40% |
| room_photo_slot | done | room_capture 虚线相框 + camera.fill + "Add photo evidence" 兜底;拍摄/选取绑定 RoomNote |
| detail_photo_strip | done | viewing_detail 横滑照条(点击全屏);空时 "No photos yet — add during a walkthrough" |
| verdict_card_render | done | verdict_card 渲染预览;无照片色块降级,导出不阻断 |
| criterion_icons | done | 9 内置 SF Symbol 映射 + criterion_edit 20 图标选择格 |

## Build / test evidence(S6)

- `logs/build.log` — `xcodebuild`(无签名、外部 DerivedData `.build/DerivedData`)**BUILD SUCCEEDED**
- `logs/test.log` — **20/20 unit tests passed**(公式归一化、缺分、换权重重排、边界、账本 grant/purchase/spend/退款/不足/非负、级联删除、walkthrough 生命周期、缺席证明、渲染器、Delete All Data)
- `logs/smoke_home_empty.png` — Simulator(iPhone 16 Pro Max 2)安装 + 冷启动截图:hero 槽、空态插画槽、4-tab、暖纸系统可见,无崩溃
- 产物:`.build/DerivedData/Build/Products/Debug-iphonesimulator/TourWise.app`

## Known gaps

- frame_compare 的 5-tab 底栏与文本 4-tab 冲突,已按文本实现(见上);若 PM 后续要 Shortlist 独立 tab 需改 routes 契约。
- App Store 元数据/截图不在 rough_app 范围(下游阶段)。
- 法律文档 URL 为模板域(tourwise.app/privacy、/terms),与 Waitwise 先例一致;真实文档托管非本阶段职责。
- 运行时 Simulator 验证(runtime_hard ids)由 verification 阶段执行;本阶段已提供 `-syntheticCapture` seam 与 .storekit 配置支持其相机/IAP 路径。

## Feature expansion consumption

- check_id: `product_maturity:feature_expansion`(清单 A2;patch 波次 b-8d7126e43a9d 补齐)
- 说明:能力图实质成熟度已由 verification attempt-1 运行时终审独立证实(见各行 evidence 引用);本节为 already_mature 举证载体,无实质缺口,不触发最小扩张实现。

```json
{
  "check_id": "product_maturity:feature_expansion",
  "product_shape": "already_mature",
  "gap_assessment": "能力图完整覆盖核心任务生命周期(新建→walkthrough→对比→Verdict→导出)、回访价值(多 WeightProfile、自定义指标、历史 viewing 复访与状态切换)、持久化(LocalStore JSON + 沙盒相对路径照片 + ExportCreditLedger)与空/加载/成功/错误/中断/恢复态(空态 CTA、Σ≠100 阻存、shortlist<2 提示、购买失败 toast、删除确认、断点 Resume)。全部经 QA 运行时终审 pass,无实质缺口。",
  "areas": [
    {
      "area_id": "criteria_system",
      "capability": "9 内置指标 seeded(稳定 UUID 幂等)+ 自定义指标即时进入打分/对比 + 内置不可删可停用",
      "evidence": "stages/verification/attempt-1/MAP.md tourwise:criteria_system pass(f05_01/f05_02/f05_05;LocalStore.swift:294-318)"
    },
    {
      "area_id": "weight_profiles",
      "capability": "多 WeightProfile + Balanced seed Σ=100 + Σ≠100 阻存差值提示 + 切 active 即时重排",
      "evidence": "stages/verification/attempt-1/MAP.md tourwise:weighted_scoring_formula pass(f05_04/f05_05/se_04;20/20 单测)"
    },
    {
      "area_id": "evidence_photos",
      "capability": "相机/相册证据照绑定 RoomNote,沙盒 Photos/<viewingId>/ 相对路径持久化,级联删除同步清理",
      "evidence": "stages/verification/attempt-1/MAP.md ios_delivery:camera_permission / photo_library_read_write_permission / tourwise:cascade_delete pass"
    },
    {
      "area_id": "normalized_weighted_ranking",
      "capability": "归一化加权排序 Σ(score×weight)/Σ(weight over 已打分且启用指标),缺分显示 '—' 不造 0,2–5 shortlist 边界",
      "evidence": "stages/verification/attempt-1/MAP.md tourwise:weighted_scoring_formula pass(ScoringEngine.swift:28-38;se_04)"
    },
    {
      "area_id": "verdict_render_export",
      "capability": "2160×2700 UIKit 确定性渲染结论卡 + Save to Photos / Share + 成功才扣 1 credit + 失败同事务退款",
      "evidence": "stages/verification/attempt-1/MAP.md tourwise:verdict_card_export pass(f03_04/f03_05;相册读回 verdict_readback_photos_library.png)"
    }
  ]
}
```

## Functional completeness final review

- check_id: `product_maturity:functional_completeness_final_review`(清单 A17;patch 波次 b-3966df17f43a 补齐)
- 说明:以下为 PDA 逐 area 终审 manifest;每项证据直接引用 verification attempt-1 MAP 的独立运行时终审结论(QA 已对全部 14 条 route 做点击级到达与端到端闭环验证)。

```json
{
  "check_id": "product_maturity:functional_completeness_final_review",
  "areas": [
    {
      "area_id": "viewing_create_and_list",
      "status": "pass",
      "entry_point": "tab_viewings(New Viewing 仅地址)",
      "state_action_outcome": "空态→创建 draft→hero/分组列表/搜索;首启空态 CTA、列表过滤跨 tab 保留",
      "chain_connection": "创建后自动进入 capture_walkthrough,产出喂 walkthrough 链",
      "evidence": "verification MAP product_maturity:core_value_and_feature_completeness / information_architecture_and_navigation pass(f01_01, f10_01/f10_02)"
    },
    {
      "area_id": "walkthrough_capture",
      "status": "pass",
      "entry_point": "capture_walkthrough + room_capture",
      "state_action_outcome": "6 房间步进/乱序/跳过/打分 1–5/备注/拍照或选图;Finish→status=toured,pending→skipped,汇总展示 scored/skipped",
      "chain_connection": "中断杀进程后 viewing_detail Resume 恢复原房间原进度;toured 产出喂 compare 链",
      "evidence": "verification MAP tourwise:walkthrough_lifecycle pass(f01_03..f01_06, f04_01..f04_03)"
    },
    {
      "area_id": "viewing_detail_management",
      "status": "pass",
      "entry_point": "viewing_detail / viewing_edit",
      "state_action_outcome": "证据照条、房间卡、状态切换(draft/toured/shortlisted/rejected)、删除确认取消不删/确认级联删(RoomNote 清空 + 沙盒照片目录消失 + compareSelection 残留清除)",
      "chain_connection": "级联删除维护 compare/verdict 数据不变量;状态机喂 compare shortlist",
      "evidence": "verification MAP tourwise:cascade_delete / workflow_coherence_and_lifecycle pass(f06_01..f06_04 + 容器回读)"
    },
    {
      "area_id": "criteria_management",
      "status": "pass",
      "entry_point": "tab_criteria / criterion_edit",
      "state_action_outcome": "9 内置 seed 可见;内置无删除入口;自定义新建即时进入指标列表/权重编辑器;启停过滤打分与对比",
      "chain_connection": "指标集喂 walkthrough 打分与 compare_board 列",
      "evidence": "verification MAP tourwise:criteria_system pass(f05_01/f05_02/f05_05)"
    },
    {
      "area_id": "weight_profiles",
      "status": "pass",
      "entry_point": "weight_editor",
      "state_action_outcome": "Σ=100 实时校验阻存 + 差值提示;多 profile 管理;切 active 即时重排",
      "chain_connection": "active profile 权重喂归一化加权排序",
      "evidence": "verification MAP tourwise:weighted_scoring_formula pass(f05_04/f05_05/f05_06)"
    },
    {
      "area_id": "compare_and_ranking",
      "status": "pass",
      "entry_point": "tab_compare / compare_board",
      "state_action_outcome": "2–5 shortlist(1 套提示、>5 阻止);固定指标列 + 横滑 viewing 列 ≥140pt;缺分 '—';#1/#2 文本徽标",
      "chain_connection": "选择集存 LocalStore 跨 tab/重启保留;排名喂 verdict_card",
      "evidence": "verification MAP product_maturity:information_architecture_and_navigation / tourwise:weighted_scoring_formula pass(store_after_f03.json, se_04)"
    },
    {
      "area_id": "verdict_render_export",
      "status": "pass",
      "entry_point": "verdict_card(Make Verdict)",
      "state_action_outcome": "渲染预览(#1 徽标/大分数/≤3 证据照拍立得/runner-up 条柱/权重依据+日期);Save to Photos 成功扣 1(100→99 三重一致:toast+store JSON+DCIM 读回);无照片色块降级不阻断;写 denied→Share 可用;余额 0→Get Credits 不阻断预览",
      "chain_connection": "导出写 ExportRecord 快照;credit 扣账接力 IAP 链",
      "evidence": "verification MAP tourwise:verdict_card_export pass(f03_04/f03_05, verdict_readback_photos_library.png)"
    },
    {
      "area_id": "credits_iap_paywall",
      "status": "pass",
      "entry_point": "paywall(tab_settings 余额卡 / credits_empty CTA)",
      "state_action_outcome": "StoreKit 2 consumable 473900(+110)/473901(+210);首启 grant +100;验证后入账、finish 前落账、按交易 id 幂等;失败 toast 不动余额;无 Restore/订阅/解锁",
      "chain_connection": "余额门槛喂 verdict 导出(spend 1);账本回读 UI 与 store JSON 一致",
      "evidence": "verification MAP ios_delivery:consumable_iap pass(CreditStore.swift, store_after_f03.json, f07_02)"
    },
    {
      "area_id": "settings_privacy_legal",
      "status": "pass",
      "entry_point": "tab_settings / privacy / 两个法律 WebView",
      "state_action_outcome": "privacy 路由展示数据边界 + 三权限实时状态;Delete All Data 二次确认后 viewings/photos/exports 清空并重置 seed;法律两独立 https WebView 加载失败友好态+Retry",
      "chain_connection": "本地优先边界与缺席证明集(mic/ATT)一致;擦除后回到首启空态链",
      "evidence": "verification MAP tourwise:local_only_privacy_surface / ios_delivery:legal_webviews pass(f12_01..f12_04, f07_04/f07_05)"
    },
    {
      "area_id": "app_shell_navigation",
      "status": "pass",
      "entry_point": "TabView 4 tab(Viewings/Compare/Criteria/Settings)",
      "state_action_outcome": "逐 tab 截图可见底栏与当前态;跨 tab 状态保留(搜索词、compareSelection、walkthrough 中断进度);legal/privacy 嵌 Settings 二级",
      "chain_connection": "承载全部主链;杀进程重进数据完整",
      "evidence": "verification MAP product_maturity:information_architecture_and_navigation / workflow_coherence_and_lifecycle pass(r01, f04 系列, f09 系列)"
    }
  ]
}
```

## Pointers

- PM 标准:`stages/pm_docs/attempt-2/MAP.md`(build/* 八章全读)
- QA 开卷:`stages/checklist/attempt-2/checks.md`(A1–A17 + B1–B11 构建对照)
- 构建命令:`cd product && xcodegen generate && xcodebuild -project TourWise.xcodeproj -scheme TourWise -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' CODE_SIGNING_ALLOWED=NO build test`(XcodeGen 2.43 二进制在 repo `.tmp/xcodegen-dist/`)
