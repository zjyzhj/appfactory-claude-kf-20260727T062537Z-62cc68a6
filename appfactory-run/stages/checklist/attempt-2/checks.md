# Checks · TourWise(验收清单正文)

本清单是 rough_app 的开卷构建标准,也是 verification 的唯一评分标准。
- PM 标准:`runs/kf-20260727T062537Z-62cc68a6/stages/pm_docs/attempt-2/MAP.md`(build/* 八章)
- Policy:`agents/FinalGateAgent/direct-repo-required-checks.json` v2.12.0,sha256 `c2ebf538a5c0c4e1385ee84bb1fe229ccbd1c30ea66aba4b24f3bd751babbcda`
- IAP 数据契约:`agents/FinalGateAgent/data-contracts/iap/yanran.json`,sha256 `b6b737cedfcec27d9104ffc4fb60e2c23479a7c2bcf6dec6bf14983959e60790`
- Run acceptance_policy:`runtime_verification_required`,simulator_runtime REQUIRED,证据技能 `ios_runtime_acceptance`。**所有 runtime_hard 检查 PASS 必须携带 Simulator 运行时证据**(安装/启动/截图/界面回读,hash 绑定);源码静默证据只能证明契约类与 source-primary 检查。
- AI:PM 声明 remote_ai=no。不得出现任何发明的 relay client、trial gate 或 AI surface;凭证封装检查不适用(无 remote AI)。
- IAP reconcile(attempt-2 已闭环):pm_docs attempt-2 已将 Commerce card、features F8、ACC-F8-IAP、data-model ExportCreditLedger、product 商业化段、routes paywall 共 6 处文案对齐 hash 绑定 yanran 目录(473900/110 credits $0.99、473901/210 credits $1.99、initial_balance=100),旧文案 "10/30 两档 / seed 3" 已全部移除。清单仍以 yanran 目录为唯一标准。

---

## A. Policy 必查集(17 项,顺序固定;final review 永远最后)

### A1. `product_maturity:core_value_and_feature_completeness` [runtime_hard]
- 锚点:ACC-REV-COMPLETE、ACC-F1-CREATE、build/features.md F1–F7、build/product.md 核心闭环。
- 要求:核心闭环"新建 Viewing → walkthrough 逐房间打分/拍照 → Compare 加权对比 → Make Verdict → 导出结论卡"每个能力都有可发现入口与端到端可达旅程;无占位控件、静态演示、断裂的功能页;范围深度与声明目标相称(4 tab 能力图,非薄捕获器)。
- 源码静默证明:路由表 14 条 route_id 在 Sources 中可定位到具体 View/状态类型;主链路调用链(建→打分→对比→导出)在源码中连通;无 TODO/占位实现。
- 运行时复现路径(L1 Simulator):启动 → tab_viewings "Add" 新建(仅地址)≤30 秒保存入列表 status=draft → viewing_detail "Start Walkthrough" → 两间房打分(含一张证据照)→ Finish 后 status=toured → tab_compare 选 2 套 → compare_board → "Make Verdict" → verdict_card 预览 → Save to Photos 成功。逐屏截图 + 界面回读。

### A2. `product_maturity:feature_expansion` [source]
- 锚点:build/features.md F4/F5/F6(指标体系、多权重方案、加权对比)、App Review risk card 4.2 行(ACC-REV-MINFUNC)。
- 要求:PackageDelivery MAP 必须含 `## Feature expansion consumption` JSON manifest(product_shape / gap 评估 / 至少一行 area)。本包能力图含 9 内置指标+自定义、多 WeightProfile、证据照、归一化加权排序、渲染导出,可按 already_mature 举证,但 already_ok 仅在证明完整核心任务生命周期、回访价值、持久化与空/加载/成功/错误/恢复态齐备时成立;任何实质缺口必须有实现或字面 blocker。薄判定则不通过,须实现最小高价值 domain-native 扩张。主题换色、通知开关、装饰 dashboard 不计。
- 证明:源码 + PDA MAP manifest;必要时运行时佐证。

### A3. `product_maturity:information_architecture_and_navigation` [runtime_hard]
- 锚点:ACC-NAV、routes-and-states.md Navigation shell 硬规则(4 tab)。
- 要求:原生底部 Tab bar(SwiftUI `TabView`)4 个持久主目的地 Viewings/Compare/Criteria/Settings,各映射一个实质不同的端到端主任务;当前目的地可见;tab 切换保留各 tab 内选中与进行中状态(筛选、已选 shortlist、编辑中 WeightProfile);legal/隐私等二级工具嵌在 Settings 内不作主 tab;前进/返回/关闭 sheet/深入/恢复不丢上下文。不允许单面例外(本产品多主任务+记录生命周期,不适用)。
- 运行时复现路径:逐 tab 截图证明可见底栏与当前态;Viewings 内筛选后切到 Compare 再切回,筛选与列表位置保留;Compare 已选集合跨 tab 保留;walkthrough 进行中切 tab 再返回进度不丢;viewing_detail push 返回、sheet 关闭路径各截图。

### A4. `product_maturity:interaction_and_state_quality` [runtime_hard]
- 锚点:routes-and-states.md 权限与恢复表、全局反馈文案;ACC-F1-DELETE、ACC-F5-WEIGHTS、ACC-F6-COMPARE 缺分态。
- 要求:每个可见控件执行其宣称动作并及时反馈;首用/空/有数据/加载/成功/禁用/校验/错误/中断/重试/取消/恢复各态无静默失败、无重复劳动、无意外数据丢失、无死路。重点态:空列表、Σ≠100 阻止保存并提示差值、缺分 "—"、shortlist<2 提示、credits_empty CTA 变 Get Credits、purchase_failed toast 不动余额、删除确认。
- 运行时复现路径:空态首屏;weight_editor 调成 Σ=90 保存被阻且提示差值;compare 只选 1 套出现提示文案;删除 viewing 弹确认、取消不删、确认级联删;StoreKit 失败 toast(可用测试注入);快速重复点保存不生成重复记录。

### A5. `product_maturity:layout_accessibility_and_responsiveness` [runtime_hard]
- 锚点:design.md Accessibility 节(320×568、Dynamic Type AX3、对比表列宽 ≥132pt 横滑、a11y label)。
- 要求:最小 320×568 不溢出(walkthrough 打分排纵向 5 行);Dynamic Type 到 AX3 不裁切不重叠;safe-area 合规;对比表横滑列头固定;照片位有 accessibilityLabel;打分控件可读值;排名不只用颜色承载(#1/#2 文本徽标)。源码审查 alone 不能过。
- 运行时复现路径:iPhone SE 档(320×568)四 tab + walkthrough + compare_board 截图;AX3 文本下首页与对比表截图;VoiceOver 语义抽查(回读 label)。

### A6. `product_maturity:visual_hierarchy_and_design_polish` [runtime_hard]
- 锚点:design.md Visual direction("Evidence board on warm paper"、palette tokens、拍立得卡)、ACC-VIS-*。
- 要求:一套产品专属设计系统(bg_paper #F6F1E7 全页面铺底、accent_brass #B4762A、卡片圆角 14、证据照 10 圆角 ≤1.2° 微倾斜)一致应用到每个可达表面:主页、二级页、导航、sheet/cover、空态、加载、校验/错误、交互反馈;层级/密度/对比/主操作位服务任务。模板感、默认感、 filler 卡堆叠不过;某表面破坏共享系统 → `visual_system_inconsistency:<surface>`。
- 运行时复现路径:全部 6 个 frame 对应路由 + paywall + privacy + criterion_edit/weight_editor 逐屏截图,同批比对跨表面一致性;空态、denied 态、错误 toast 表面入镜。源码审查 alone 不能过。

### A7. `product_maturity:feature_expressive_ui_ux_and_motion` [runtime_hard]
- 锚点:design.md Motion & interaction language(5 个 moment + tokens + Forbidden)、ACC-MOT-*。
- 要求:全产品(非仅首页)有辨识度的"证据板"体验;动效强制且全局,覆盖三观测点:(a) 表面间导航/转场,(b) 状态变化(loading→content、empty→populated),(c) 主操作确认/反馈。moment 覆盖:mot_entry_settle(hero 落位+列表 stagger)、mot_commit_photo(照片飞入落板+medium haptic)、mot_success_verdict(发牌式入场+#1 徽标延迟弹入)、mot_empty_breathe(2.4s ±4pt 呼吸一次后静止,非无限循环)、mot_rank_regrow(权重切换条柱重生长)。禁轮播/粒子/confetti/rank 闪爆。Reduce Motion 五 moment 全部退化为声明等价且价值不丢。事实静态界面或仅首页动效 → `motion_floor_not_met:<surface>`;仅首页精修 → `homepage_only_polish`;仅换色/圆角/阴影模板过 → `template_shell_visual_pass`。
- 运行时复现路径:冷启动首页首帧录屏/连拍;room_capture 确认照片落板;verdict_card Make Verdict 入场;空态呼吸一次后静止;weight_editor 切 active 回 compare 条柱重生长;开 Reduce Motion 重走五 moment 验证静态等价。

### A8. `product_maturity:workflow_coherence_and_lifecycle` [runtime_hard]
- 锚点:routes-and-states.md Viewing.status 状态机、data-model.md 关系与不变量、features.md 迭代跑道(非 v0 不查)。
- 要求:能力构成连贯生命周期:walkthrough 产出喂 compare,compare 产出喂 verdict,导出写 ExportRecord 快照;draft→toured→shortlisted→rejected 可互转且术语一致;首用/复用/重启/回访/数据增长旅程可用;重启后数据仍在;20+ viewing 列表仍可用;积分/隐私等二级工具不抢主价值。
- 运行时复现路径:完整走一遍建→走→比→导;杀进程重进数据与状态保留;draft 中断后 "Resume Walkthrough" 回原房间原进度;多 viewing 数据增长下列表滚动与分组正常。

### A9. `ios_delivery:consumable_iap` [source · 非 runtime_hard]
- 锚点:ACC-F8-IAP、ACC-REV-IAP、ai-and-privacy Commerce card、data-model ExportCreditLedger。**标准以 yanran.json(hash 见文头)为准**。
- 要求:
  - StoreKit consumable,商品取 yanran 目录两档(默认 473900/110 credits $0.99 与 473901/210 credits $1.99;如改档必须仍是目录内 product_id 原样);product ID 完整精确、仅内部使用、UI 不外露 ID。
  - 初始余额 = 目录 initial_balance **100**(首启 seed,transactions 记 grant);PM 文案 attempt-2 已与目录一致。
  - 购买经交易验证后按目录 amount 入账,余额展示于 tab_settings;交易 finish 前不落 purchase 记录;失败 toast("Purchase didn't complete. Your credits were not changed. Try Again")不改余额。
  - 消费点:verdict_card 导出(Save to Photos / Share 成功)每次扣 1,导出成功才扣,spend 与渲染同事务(渲染失败退款);余额 0 时 CTA 变 "Get Credits" → paywall,不阻断预览。
  - consumable 无 Restore Purchases 入口;无订阅/解锁/买断文案。
- 证明:源码定位 StoreKit 封装、目录 ID 字面、入账/扣减/退款事务逻辑、paywall 与 balance UI、无 restore 符号;单测覆盖入账/失败/扣减/退款。

### A10. `ios_delivery:legal_webviews` [source]
- 锚点:ai-and-privacy.md 法律节;routes 表 tab_settings。
- 要求:隐私政策与用户协议两个独立应用内 WebView 入口,各自由独立 HTTPS 模板 URL 支撑,从 tab_settings 可达;加载失败有友好态。
- 证明:源码定位两个入口、两个不同 https URL、WebView 组件与失败处理。

### A11. `ios_delivery:functional_images` [runtime_hard]
- 锚点:features.md 功能-媒体扩张节、design.md In-app image slots、ACC-VIS-MEDIA。
- 要求:≥4 个不同任务/生命周期上下文页面展示图片:tab_viewings(hero + 列表封面)、viewing_detail(证据照条)、room_capture(采集预览)、compare_board(证据缩略)、verdict_card(渲染卡);其中 ≥3 页主功能图占可用视口 30–70% 且保留功能上下文(viewing_detail 照条+打分表、room_capture 预览+打分控件、verdict_card 卡片+操作按钮)。计入图必须绑定真实域记录/用户动作/持久化结果;bundle 资产、营销图、静态插画、seed mock 不计入 4/3 阈值;同图换标题不重复计。
- 运行时复现路径:五页逐屏截图并标注视口占比;照片绑定 RoomNote 后在 detail/compare/verdict 三处可见;无照片时色块降级路径截图。

### A12. `ios_delivery:camera_permission` [runtime_hard]
- 锚点:ACC-F3-PHOTO、ACC-F3-DENIED、routes 权限表、ai-and-privacy 权限清单、risk card 5.1.1。
- 要求:`NSCameraUsageDescription` 产品专属字面 "TourWise uses the camera to attach evidence photos to the room you are scoring.";仅 room_capture 点 "Take Photo" 时 JIT 请求;denied/restricted 原位三继续项 Choose Photo / Add without a photo / Retry Camera,全源码无 "Open Settings"/`openSettingsURLString`;取消保留进行中打分。**Simulator 无相机硬件:必须提供确定性捕获替代 seam(如 UI 测试注入 capture provider),用合成媒体走通 granted 捕获→绑定 RoomNote 全旅程**;仅走 camera_unavailable 分支不过。
- 运行时复现路径:注入 seam 后 Take Photo → 合成照片落板绑定房间;denied 态三按钮逐一验证应用内继续;pre-prompt 时机截图(启动不弹)。

### A13. `ios_delivery:photo_library_read_write_permission` [runtime_hard]
- 锚点:ACC-F3-PHOTO、ACC-F7-VERDICT、routes 权限表。
- 要求:读 `NSPhotoLibraryUsageDescription`("TourWise lets you attach existing photos from a viewing to its room scores.")与写 `NSPhotoLibraryAddUsageDescription`("TourWise saves your verdict card to Photos so you can share it with family.")产品专属字面;读在 room_capture 选图、写在 verdict Save to Photos 时 JIT;limited/denied/restricted/retry/取消均应用内继续(读 denied 空态文案、写 denied 时 Share 仍可用);禁 Settings 跳转。**CTA 可见+源码证明不过:必须运行时真实 granted 导入/浏览与真实 granted 保存/导出各一次绑定域记录**,另覆盖 limited/denied/取消恢复。
- 运行时复现路径:Photos 选图 → 绑定 RoomNote 入照条;verdict Save to Photos → 相册可读回 + 扣 1 credit;写 denied → Share sheet 可用;读 limited → 可选范围继续。

### A14. `ios_delivery:microphone_permission_boundary` [runtime_hard · 缺席分支]
- 锚点:ai-and-privacy.md 权限清单(Microphone 声明缺席);能力图 F1–F8 无任何音频工作流(无语音备注/视频录制)→ 缺席分支合法。
- 要求(缺席证明集,缺一不可):任一 Info.plist 无 `NSMicrophoneUsageDescription`;全源码无 `AVAudioRecorder`/`AVAudioApplication` 等音频录制 API 引用;PrivacyInfo 一致;专项缺席测试;运行时全主流程扫描零意外麦克风弹窗。
- 运行时复现路径:主流程全链路扫一遍确认无麦克风请求。

### A15. `ios_delivery:app_tracking_transparency` [runtime_hard · 缺席分支]
- 锚点:ai-and-privacy.md(ATT 声明缺席:无广告/追踪/数据出设备);无分析 SDK。
- 要求(缺席证明集):无 `NSUserTrackingUsageDescription`;无 `ATTrackingManager`/`AdSupport`/IDFA 引用;`PrivacyInfo.xcprivacy` 声明 `NSPrivacyTracking=false`;专项缺席测试;运行时全主流程扫描零追踪弹窗;无追踪域名网络调用(StoreKit 除外)。
- 运行时复现路径:全链路扫描确认无 ATT 弹窗。

### A16. `ios_delivery:keyboard_dismissal` [source]
- 锚点:ACC-KB、routes 全局反馈(所有输入框失焦/return 收起)。
- 要求:每个文本输入面(viewing_edit、room 备注、criterion_edit、weight 方案名等)有点按空白/return 等明确收键盘交互且不丢已输入内容。
- 证明:源码定位各输入面的收键盘实现(scrollDismissesKeyboard/onSubmit/tap-away)与值保留。

### A17. `product_maturity:functional_completeness_final_review` [最后]
- 锚点:全部 ACC 行。
- 要求:终审每个声明能力与可达功能链:入口、状态迁移、用户动作、可观测结果、持久化、跨功能接力、失败与恢复、用户可见完成。PackageDelivery MAP 必须含 `## Functional completeness final review` JSON manifest(area_id / status / entry_point / state_action_outcome / chain_connection / evidence),任何 area 未审/无证据/blocked 不得 ready。笼统"已完成"不算证据。
- 证明:PDA MAP manifest + 源码/运行时抽查。

---

## B. 产品专项检查(PM ACC 落锤,补充于必查集之外)

### B1. `tourwise:walkthrough_lifecycle` [runtime_hard]
- 锚点:ACC-F2-WALKTHROUGH。
- 要求:房间步进可打分 1–5/备注/跳过/乱序跳转;Finish 后 status=toured 且 pending 记 skipped;finish 汇总展示已评/跳过;中断后 viewing_detail "Resume Walkthrough" 恢复原房间原进度;单房间操作 ≤10 秒可完成。
- 运行时路径:进 walkthrough 乱序跳房间打分 → 中断杀进程 → Resume 验证现场 → Finish 验证状态机与汇总。

### B2. `tourwise:weighted_scoring_formula` [source + 单测]
- 锚点:ACC-F5-WEIGHTS、ACC-F6-COMPARE、data-model.md 加权公式。
- 要求:归一化加权分 = Σ(score[c]×weight[c]) / Σ(weight[c] over 已打分且启用指标);缺分单元格显示 "—" 不造 0 分;Σ≠100 阻止保存并提示差值;切 active profile 后 compare 即时重排;2–5 套 shortlist 边界(1 套提示、>5 阻止)。
- 证明:源码定位公式实现 + 单测覆盖(含缺分归一化、权重切换、边界)。

### B3. `tourwise:criteria_system` [source]
- 锚点:ACC-F4-CRITERIA。
- 要求:9 内置指标 seeded(Natural Light / Noise / Space & Storage / Condition / Kitchen / Bathroom / Location & Commute / Building & Safety / Price Fit);内置不可删可停用;自定义指标新建后即时进入 walkthrough 与 compare;停用指标不再出现在打分与对比。
- 证明:seed 源码/迁移、删除禁用、启停过滤逻辑、新建即生效路径。

### B4. `tourwise:cascade_delete` [source + runtime]
- 锚点:ACC-F1-DELETE、data-model 级联不变量。
- 要求:删除 Viewing 有确认弹窗(文案 "Delete this viewing? Its scores and photos will be removed from this iPhone.");确认后 RoomNote 与沙盒 `Photos/<viewingId>/` 本地照片文件级联删除;取消不删。
- 证明:级联实现源码 + 运行时删后文件系统核查。

### B5. `tourwise:verdict_card_export` [runtime_hard]
- 锚点:ACC-F7-VERDICT。
- 要求:结论卡含排名 #1(徽标)、≥1 张代表证据照(无照片时纯色块+分数排版降级且不阻断导出)、权重依据、日期;Save to Photos 成功扣 1 credit 且相册可读回;写权限 denied 时 Share 系统分享仍可用;余额 0 预览不阻断、CTA 变 Get Credits。
- 运行时路径:有照/无照两种导出;denied Share 路径;余额 0 → paywall 跳转。

### B6. `tourwise:image_slot_app_icon` [source/build]
- 锚点:ACC-VIS-ICON、design.md slot `app_icon`。
- 要求:Asset Catalog 存在 AppIcon imageset(暖纸底+黄铜房屋+星标方向)且被构建引用;`criterion_icons` 指标图标映射(内置资产或 SF Symbol 表)存在。
- 证明:asset catalog 文件 + 构建引用。

### B7. `tourwise:image_slot_home_hero` [source + runtime]
- 锚点:ACC-VIS-HERO、slot `home_hero`。
- 要求:首页顶部 hero 槽视图存在(asset `hero_home` + 渐变遮罩 + 标题叠层,约 30% 屏高);资产缺失时 `#E9DFC9` 渐变 + SF Symbol `house.fill` 兜底可见。
- 证明:源码槽视图 + 兜底分支;运行时首页截图。

### B8. `tourwise:image_slot_empty_illustration` [source + runtime]
- 锚点:ACC-VIS-EMPTY、slot `viewings_empty_illustration`。
- 要求:空列表时居中空态插画槽可见(asset `empty_viewings`,配 "No viewings yet" 与 Add 按钮);兜底 SF Symbol `photo.stack` 56pt。
- 证明:源码 + 运行时首启空态截图。

### B9. `tourwise:image_slot_photo_media` [source + runtime]
- 锚点:ACC-VIS-MEDIA、slots `room_photo_slot` / `detail_photo_strip` / `verdict_card_render`。
- 要求:room_capture 照片预览槽(虚线相框 + camera.fill + "Add photo evidence" 兜底)、viewing_detail 横向证据照条(点击全屏;无照时 "No photos yet — add during a walkthrough" 文本行)、verdict_card 渲染预览槽(色块降级)三路径存在。
- 证明:源码三槽 + 运行时三处截图。

### B10. `tourwise:local_only_privacy_surface` [source + runtime]
- 锚点:ACC-REV-PRIVACY、routes `privacy`。
- 要求:全部数据仅本地;照片相对路径持久化(禁绝对路径);tab_settings → privacy 路由可达,展示数据边界说明、权限状态、"Delete All Data" 二次确认且执行后数据清空;Info.plist 仅 Camera/PhotoLibrary/PhotoLibraryAdd 三条权限文案,无未声明权限。
- 证明:源码 + 运行时 privacy 页与 Delete All Data 旅程截图。

### B11. `build:headless_xcodebuild` [build]
- 锚点:run acceptance_policy `required_source_proofs`(xcode_source_build / source_unit_tests / source_artifact)。
- 要求:Xcode 可用时 `xcodebuild`(无签名、外部 DerivedData)构建通过;单元测试通过(权重公式、账本不变量、缺席测试等);构建产物可定位。
- 证明:构建日志 + 测试日志路径。

---

## C. 说明

- ACC-REV-DIFF(4.3):无 check_id,由 run dedupe 记录证明产品指纹可区分,verification 时引用 dedupe 记录即可,不在本清单单列。
- ACC-MOT-* 五行并入 A7(moment 覆盖判定);ACC-REV-COMPLETE/MINFUNC/PRIVACY/IAP 分别映射 A1/A2/A12+A13+B10/A9,不新增 id、不弱化 policy 语义。
- verification 评分规则:runtime_hard id 在 `runtime_verification_required` 下无 Simulator 运行时证据 → 一律 block,字面 `runtime_mode_missing_runtime_evidence:<check_id>`。
