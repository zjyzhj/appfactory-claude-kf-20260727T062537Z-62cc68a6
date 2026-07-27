# Features · TourWise

能力图:看房记录(生命周期)→ 现场证据采集(相机/相册)→ 指标与权重体系 → 加权对比 → 结论卡交付。四 tab 各自承载端到端任务,互为下游。

## F1 · Viewing 管理(tab_viewings / viewing_detail / viewing_edit)
建/改/删看房记录;status 流转;列表按 status 分组 + 搜索。
- 成功信号:30 秒内从空态到首个 Viewing 创建完成;删除有确认;列表均分即时刷新。
- 相关 route:tab_viewings, viewing_detail, viewing_edit。

## F2 · 引导式 Walkthrough 打分(capture_walkthrough / room_capture)
房间步进打分(1–5)、备注、跳项、任意顺序、中断恢复;完成后自动 toured。
- 成功信号:单房间操作 ≤10 秒;中断后 Resume 回到原房间原进度;finish 汇总页展示已评/跳过。
- 相关 route:capture_walkthrough, room_capture。

## F3 · 证据照采集与展示(room_capture / viewing_detail)
记录绑定的相机即时拍摄 + 相册选图;照片绑定 RoomNote;detail 页证据照条;删除级联。
- 成功信号:拍摄/选取的照片出现在对应房间;denied 时三选一应用内继续(Choose Photo / Add without a photo / Retry Camera),无 Settings 跳转。
- 相关 route:room_capture, viewing_detail。

## F4 · 指标体系(tab_criteria / criterion_edit)
9 个内置指标 + 自定义指标(名/图标),启停与排序;停用不进入打分与对比。
- 成功信号:新建自定义指标即时出现在 walkthrough 与 compare;内置不可删。
- 相关 route:tab_criteria, criterion_edit。

## F5 · 权重方案(weight_editor)
多 WeightProfile;滑杆分配 0–100,Σ=100 实时校验;一键切换 active。
- 成功信号:切换 active 后 tab_compare 排名即时重排;Σ≠100 时保存被阻止并指出差值。
- 相关 route:weight_editor。

## F6 · 加权对比(tab_compare / compare_board)
shortlist 选 2–5 套;排名列表(归一化加权分 + 条柱);并排对比表(指标 × viewing,缺分 "—");证据照缩略可点看大图。
- 成功信号:改权重 → 排名可观察变化;缺数据不崩溃不造 0 分。
- 相关 route:tab_compare, compare_board。

## F7 · Verdict 卡与导出(verdict_card)
渲染结论卡(排名 #1–#3、各 1 张代表证据照、权重依据、日期);Save to Photos(写权限)/ 系统 Share;每次成功导出消耗 1 Export Credit;余额不足进 paywall。
- 成功信号:导出后相册可见卡片;余额同步扣减;写权限 denied 时 Share 路径仍可用。
- 相关 route:verdict_card, paywall。

## F8 · Consumable IAP(tab_settings / paywall)
yanran consumable balance catalog:Export Credit 10/30 枚包;购买入账、余额展示、交易失败友好提示;无 Restore(consumable)。
- 成功信号:购买后余额增加且 transactions 可查;失败 toast 不丢余额;无订阅/解锁文案。
- 相关 route:paywall, tab_settings。

## 功能-媒体扩张(图片功能映射)
- ≥4 页展示图片:tab_viewings(hero + 列表封面照)、viewing_detail(证据照条)、room_capture(采集预览)、compare_board(证据缩略)、verdict_card(渲染卡)。
- ≥3 页图片占屏 30–70% 且保留功能上下文:viewing_detail(照条 + 打分表)、room_capture(预览 + 打分控件)、verdict_card(卡片 + 操作按钮)。

## 迭代跑道(非 v0)
搬家清单、房贷试算、伴侣协同、日历提醒、更多导出模板、城市指标模板包。
