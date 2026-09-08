# 当前计划

日期：2026-08-30

## 当前已验收基线：MT5 v32.14

- [x] v32.13 完成“多单/空单无阶梯组合保本”的 UI、命令、运行时快照及持久化接入；按钮点击可实际建立无阶梯组合。
- [x] 无阶梯组合成员暂停普通阶梯触及和执行，并清除旧的未成交触及/待重试；取消后只按当刻行情重新判断未完成阶梯。
- [x] v32.14 隐藏无阶梯组合成员的普通阶梯 `L1-L10` 线及标签，保留开仓价标注；非成员和普通组合保持原显示。
- [x] UI 外观以及既有自动保本、手动止损、追踪止损、平仓逻辑保持不变。
- [x] MetaEditor 编译：`0 errors, 0 warnings`；MT5 合同测试：`205/205 OK`。
- [x] 用户已完成真实图表验收，确认 v32.14 正常。
- [ ] 后续仅在出现新的实盘问题或明确需求时继续施工，不重做已验收工作。

## 历史验收基线：MT5 v32.05

- [x] v32.05 修复订单操作页自动管理三档按钮：切换运行时自动保本模式，不再误调用一次性手动止损。
- [x] v32.05 修复阶梯止盈开关，使其实际启用/停用普通阶梯止盈处理。
- [x] UI 外观和既有手动止损、追踪止损、平仓逻辑保持不变。
- [x] MetaEditor 编译：`0 errors, 0 warnings`；相关 MT5 合同测试：`67/67 OK`。
- [x] 用户已完成实盘验收，确认 v32.05 正常。

## 更早验收基线：MT5 v32.04

- [x] v32.04 已完成客户端独立账本、启动重建和北京时间整点/半点核对清理。
- [x] MT5 账本已从 `FILE_COMMON` 改为当前终端本地 `MQL5\\Files`，按账号、服务器和品种隔离。
- [x] 实盘交易已恢复正常，用户验收成功。
- [x] 最新账本快照：11 个普通持仓管理对象、11 个阶梯状态、3 条操作记录，恢复锁已解除。
- [x] MetaEditor 编译：`0 errors, 0 warnings`；指定 MT5 合同测试 `24/24 OK`。
- [ ] 后续仅在出现新的实盘问题或明确需求时继续施工，不重做已验收工作。

## 历史目标（已完成）

以 HTML 预览 `75%` 在本机 Windows `150%` 缩放下的实际效果为基准，把 `canvas-panel-demo-v5` 重建为 MT4 `100% = 563px` 的统一像素坐标，同时冻结颜色、纹理、页面结构、交易逻辑、v4 和正式 v31.02。

## 本轮计划（2026-08-04）

- [x] 建立三页 HTML 75% 实测度量表，固定宽度 `563px` 和高度 `1442/1294/1425px`。
- [x] 重写 v5 展开态几何、留白、按钮、输入框、命中区和统一比例缩放。
- [x] 撤销失败的逐字符字体分流；Canvas 与临时输入框改用 `Microsoft YaHei UI` 整串绘制，仅在整字体加载失败时后备 Arial，继续使用原字号和 `FW_NORMAL/FW_MEDIUM/FW_SEMIBOLD`。
- [x] 统一把 HTML CSS 像素字号转换为 MT4 Canvas 点值：字体入口与临时输入框使用 `4/3` 比例，原有角色字号、字重与所有几何坐标不变。
- [x] 完成临时 `OBJ_EDIT` 参考字号 `15px` 的 RED→GREEN。
- [x] 完成 v5 专项、全量回归、安全扫描、双位置编译、Experts 同步和哈希核对。
- [ ] 用户在真实 MT4 中以 EA `100%` 对照 HTML `75%` 截图验收三页；若存在误差，只修改量出的目标项。

## 历史计划

- [x] 新建 v31.00，保留 v30.10 源码与哈希不变。
- [x] 集中最终主题色，增加 `绿涨红跌 / 红涨绿跌` 设置。
- [x] 扩展四档追踪 `50/100/200/300` 与四档平仓 `5/10/25/50%`。
- [x] 实现统一卡片、实心命令色和 `18%` 交互提示区。
- [x] 增加关键交易函数防漂移合同并完成全量回归。
- [x] 完成项目/Experts 双编译、部署、哈希核对和文档同步。
- [x] 根据 v31.00 实机截图定位 MT4 默认凹陷边框和旧布局结构残留。
- [x] 新建 v31.01，显式使用平面卡片并重建主要页面层级。
- [x] 以函数体等价合同确认关键交易函数与 v31.00 一致。
- [x] 完成 v31.01 专项、全量回归、双位置编译、部署和哈希核对。
- [x] 用户返回 v31.01 实机截图，确认原生方角控件仍明显偏离 HTML。
- [x] 确认改用 MT4 `CCanvas`，不为 UI 单独迁移 MT5。
- [x] 确认先做“订单操作”单页、无交易功能的独立实机原型。
- [x] 定稿 Canvas 原型设计与安全边界。
- [x] 用户复核 Canvas 原型书面规格。
- [x] 编写实施计划并实现、测试、编译和部署 v1 演示 EA。
- [x] 用户挂载 v1 并确认 Canvas 圆角路线可行，同时指出字号、排版和日志密度仍有差距。
- [x] 新建并部署独立 v2：加入 `0.75` 字号换算、固定纵向栅格、右对齐辅助文字和 `214px` 日志卡片。
- [x] 用户挂载 v2 并确认整体效果良好，指出四处局部细节。
- [x] 新建并部署独立 v3：固定版本/状态槽位、加高当前选择区、日志底部留白、统一柔和蓝与白字。
- [x] 新建并部署独立 v4：标题三项共用水平中心线、指标框加高至 `50px`、补齐组合保本页和设置页。
- [x] 设置页采用 Canvas 静态数值框，点击时只创建一个临时原生 `OBJ_EDIT`，提交后校验、删除并重绘。
- [x] 用户确认 v4 三页排版及后两个页签结构无需再改。
- [x] 全部按钮按最终 HTML v6 一一迁移填充色、文字色和彩色边框；四档快捷按钮使用四级蓝紫实色。
- [x] 新建 `v30-panel-color-pool-v2.html`，12 个按钮分别选择背景色和黑/白字，公共色库扩展为 63 色。
- [x] 浏览器实际验证两个目标按钮独立换色、结果清单同步且横向溢出为 0。
- [x] Canvas v4 顶栏增加最小化按钮，当前收起尺寸为 `390 x 90`，展开后保留活动页和内存设置。
- [x] 增量专项 `17/17`、全量 `214/214`，双位置编译、部署、安全扫描和哈希核对完成。
- [x] 用户在新版颜色池中确定 12 个按钮的最终背景色和文字色。
- [x] 完成最终 `650 x 1545 / 51px` 源码迁移、专项回归、全量回归与安全扫描。
- [x] 彩色快捷按钮描边改为与填充同色，删除旧独立亮色描边函数。
- [x] 圆角弧线改为浮点坐标 `PixelSetAA()` 采样，不再先整数化圆周点。
- [x] 默认实际尺寸改为 `600 x 1426`；`650 x 1545` 仅保留为布局参考坐标。
- [x] 取得授权后完成项目/Experts 双位置 MetaEditor 编译、部署和哈希核对。
- [x] 定稿 v31.02 Canvas 正式迁移规格和实施计划。
- [x] 新建 v31.02 并完成价格差标注合同。
- [x] 迁移 Canvas 静态层、动态文字层、临时输入和真实动作映射。
- [x] 完成专项/全量回归、双位置编译和 Experts 部署。
- [x] 修复 Canvas 同一次单击被 `OBJECT_CLICK` 与 `CLICK` 重复执行，导致“阶梯止盈”开关关闭后立即又开启。
- [ ] 用户在真实 MT4 中挂载 `自动保本_v31.02`，确认三页视觉、单击、输入和最小化/恢复。

## 已完成

- [x] 完整恢复并记录本任务历史中的交易规则和用户取舍。
- [x] 定稿人工加入/退出管理、组合保本、所选订单操作、“距下一阶”和正式三页签面板。
- [x] 以 `src/自动保本_v29.1.mq4` 为只读基线，新建 `src/自动保本_v30.00.mq4`。
- [x] 完成实施计划 Task 1-12，接入正式面板、组合状态、持久恢复、交易调度和可视化。
- [x] 删除旧散落按钮 UI、旧 UI 参数和禁止的过度设计残留。
- [x] 部署 v30.00 到 MT4 `Experts`，生成 `.ex4`，核对项目/Experts 源码一致。
- [x] 项目源码和 Experts 副本均通过 MetaEditor 编译。
- [x] 项目全量 Python 回归 `129/129 OK`。
- [x] 新建 `docs/v30-demo-checklist.md`，列出 16 个真实 broker/demo 场景。
- [x] 根据 v30.00 首次上机截图定位三项问题并建立失败测试。
- [x] 新建 `src/自动保本_v30.01.mq4`，恢复并锁定 v30.00 原哈希。
- [x] 三项修复完成 RED→GREEN，项目全量回归更新为 `133/133 OK`。
- [x] v30.01 项目源码和 Experts 副本均完成 MetaEditor 编译与哈希同步。
- [x] 根据 v30.01 第二次上机表现确认：订单对象单击后紧随的 `CHARTEVENT_CLICK` 会清空刚建立的选择。
- [x] 新建 `src/自动保本_v30.02.mq4`，加入一次性 500ms 重复事件过滤，保留之后单击空白清除选择。
- [x] 新增 `Panel_Page_Vertical_Spacing=24`，代码限制为 `0-40px`；默认面板参数改为 `10/120/500/1150`。
- [x] 同步 HTML 原型默认值，完成专项 RED→GREEN 和项目全量 `135/135 OK`。
- [x] v30.02 项目源码和 Experts 副本均完成 MetaEditor 编译、部署和哈希同步。
- [x] 用户现场确认 v30.02 的订单单击选择问题已修复。
- [x] 确认红框处根因是页签、页面起点和选择区按钮继续使用固定 Y 坐标，绕过 `Panel_Page_Vertical_Spacing`。
- [x] 新建 `src/自动保本_v30.03.mq4`，使同一间距参数覆盖标题到页签、页签到首块、选择文字到管理按钮。
- [x] 顶部间距测试完成 RED→GREEN；项目全量回归更新为 `137/137 OK`。
- [x] v30.03 项目源码和 Experts 副本均完成 MetaEditor 编译、部署和哈希同步。
- [x] v30.04 将纵向间距改为运行时状态，采用累计顶部布局，并在“面板位置、大小与间距”中增加 `页面纵向间距` 编辑框。
- [x] v30.04 完成两项专项 RED→GREEN、`26/26` 面板/基线专项、`139/139` 全量回归、双位置编译、部署和哈希同步。
- [x] v30.05 使用显式 BUY/SELL 价格比较修复多单阶梯触及误判；扩大中文标签估宽和右边距；拆分顶部统计；新增 `24-48px` 功能按钮高度设置。
- [x] v30.05 专项 `29/29`、全量 `143/143`，项目与 Experts 双编译、部署和哈希同步完成。
- [x] v30.06 将两个保本按钮改为同行半宽，把 `触发下一阶止盈` 移到订单操作页最底部并设为全宽；产品与 HTML 原型保持一致。
- [x] v30.06 专项 `31/31`、全量 `146/146`，项目与 Experts 双编译、部署和哈希同步完成。
- [x] 定位 v30.06 手动部分平仓重复阶梯的根因：`.A=awaitingRollover` 只覆盖 EA 自己发起的部分平仓。
- [x] v30.07 增加具有明确 broker lineage 的手动/外部部分平仓状态继承。
- [x] v30.07 ticket/ownership/启动恢复专项 `38/38`、全量 `148/148`，项目与 Experts 双编译、部署和哈希同步完成。
- [x] v30.08 休眠空窗隔离和 4109 待重试完成 RED→GREEN。
- [x] v30.08 专项 `41/41`、全量 `151/151`，项目与 Experts 双编译、部署和哈希同步完成。
- [x] v30.09 完成普通后继票前置迁移、三档手动平仓、交易权限阶梯门控、订单页重排和盈亏标签。
- [x] v30.09 专项 `74/74`、全量 `164/164`，项目与 Experts 双编译、部署和哈希同步完成。
- [x] v30.10 将双向突破区固定到订单页底部、交互提示区上方；专项 `41/41`、全量 `166/166`，双编译、部署和哈希同步完成。
- [x] v31.00 完成最终美化与四档快捷值；专项 `6/6`、全量 `172/172`，双编译、部署和哈希同步完成。
- [x] v31.01 修复默认凹陷边框、卡片比例和页面层级；专项 `5/5`、全量 `177/177`，双编译、部署和哈希同步完成。
- [x] Canvas v2 专项 `7/7`、当时全量 `190/190`，双位置编译、部署和哈希同步完成。
- [x] Canvas v3 专项 `7/7`、全量 `197/197`，双位置编译、部署和哈希同步完成。
- [x] Canvas v4 专项 `11/11`、全量 `208/208`，双位置编译、部署、安全扫描和哈希同步完成。

## 当前权威文档

- 稳定项目事实：`docs/project-memory.md`
- Canvas 原型设计：`docs/superpowers/specs/2026-07-31-mt4-canvas-panel-demo-design.md`
- Canvas 原型实施计划：`docs/superpowers/plans/2026-07-31-mt4-canvas-panel-demo.md`
- Canvas v2 校准设计：`docs/superpowers/specs/2026-07-31-mt4-canvas-panel-demo-v2-design.md`
- Canvas v2 实施计划：`docs/superpowers/plans/2026-07-31-mt4-canvas-panel-demo-v2.md`
- Canvas v3 细节设计：`docs/superpowers/specs/2026-07-31-mt4-canvas-panel-demo-v3-design.md`
- Canvas v3 实施计划：`docs/superpowers/plans/2026-07-31-mt4-canvas-panel-demo-v3.md`
- Canvas v4 三页设计：`docs/superpowers/specs/2026-07-31-mt4-canvas-panel-demo-v4-three-pages-design.md`
- Canvas v4 三页实施计划：`docs/superpowers/plans/2026-07-31-mt4-canvas-panel-demo-v4-three-pages.md`
- 当前美化设计：`docs/superpowers/specs/2026-07-31-v30-panel-beauty-design.md`
- 当前美化实施计划：`docs/superpowers/plans/2026-07-31-v31-panel-beauty.md`
- 完整工作设计：`docs/superpowers/specs/2026-07-27-v30-order-selection-and-basket-breakeven-design.md`
- 产品实施计划：`docs/superpowers/plans/2026-07-28-v30-product-implementation.md`
- 已验证事实与历史审查：`docs/findings.md`
- 恢复状态：`docs/progress.md`
- 本轮记录：`docs/task-log-2026-07-31.md`
- 真实环境验收：`docs/v30-demo-checklist.md`

## 当前验收

- v5 专项回归：`24/24 OK`；全量 `261` 项中仅有既有 v29 HTML 说明书缺失导致的 `2 failures + 3 errors`，没有 v5 新失败。
- 项目与 Experts 两份 v5 源码均为 `Result: 0 errors, 0 warnings`；安全扫描为 `SAFETY_SCAN_OK`。
- v5 MQ4 SHA256：`71E8E32EC1B4029AE8A6FE2E0B8476C9EBA6862A2CD4E2541593DD3F7DF7474D`。
- 最终同步 EX4 SHA256：`376689FD8897B869C7E9613B011A8D31E726F377EED46B8D25950D38FD4650D1`；项目与 Experts 一致。
- Noto 字体资源文件保留在项目中，但本版 v5 不再引用或嵌入。
- 冻结文件未变：v4 为 `B969E86B42DF71F9DADF02F76E178407C698B89520AD6902AC6AD616985E6727`；正式 v31.02 为 `701D86C9378DF8AB1AB2BA033DB83A967A4FE2248076D134F4FBD579D09E4CE4`。

- v31.02 Canvas 专项回归：`17/17 OK`；项目全量 Python 回归：`237/237 OK`。
- v31.02 项目源码与 Experts 副本均为 `Result: 0 errors, 0 warnings`。
- v31.02 两份源码 SHA256 均为 `701D86C9378DF8AB1AB2BA033DB83A967A4FE2248076D134F4FBD579D09E4CE4`。
- Experts `自动保本_v31.02.ex4`：`462884` 字节；v31.01 SHA256 保持 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。

- 按钮选色器与 Canvas v4 专项回归：`17/17 OK`。
- 项目全量 Python 回归：`214/214 OK`。
- Canvas v4 项目源码与 Experts 副本编译：均为 `Result: 0 errors, 0 warnings`。
- Canvas v4 项目源码与 Experts 副本 SHA256：`3E5FF821FAB342C6B693F33DE64C0C880ABDEB6D9B31ED9479DFABBC616FC8D1`。
- Experts `canvas-panel-demo-v4.ex4`：`104730` 字节（体积不作为源码一致性条件）。
- v3 SHA256 保持 `89A5011E9ED0064F5DEF82BFEF23ACAF840515BF2A46324C99B2BFE4E996767C`。
- 正式 v31.01 SHA256 保持 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。
- Canvas v3 专项回归：`7/7 OK`。
- 项目全量 Python 回归：`197/197 OK`。
- Canvas v3 项目源码与 Experts 副本编译：均为 `Result: 0 errors, 0 warnings`。
- Canvas v3 项目源码与 Experts 副本 SHA256：`89A5011E9ED0064F5DEF82BFEF23ACAF840515BF2A46324C99B2BFE4E996767C`。
- Experts `canvas-panel-demo-v3.ex4`：`47080` 字节（体积不作为源码一致性条件）。
- v2 SHA256 保持 `756B8BA18A22AAB08674B161413B7988D61967E4BDF47357986790732B7C430F`。
- v31.01 视觉专项回归：`5/5 OK`。
- 项目全量 Python 回归：`177/177 OK`。
- v31.01 项目源码与 Experts 副本编译：均为 `Result: 0 errors, 0 warnings`。
- v31.01 项目源码与 Experts 副本 SHA256：`2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。
- Experts `自动保本_v31.01.ex4`：`371100` 字节（体积不作为源码一致性条件）。
- v31.00 专项回归：`6/6 OK`。
- v31.00 当时项目全量 Python 回归：`172/172 OK`。
- v31.00 项目源码与 Experts 副本编译：均为 `Result: 0 errors, 0 warnings`。
- v31.00 项目源码与 Experts 副本 SHA256：`533FCA545B857C65DC6DB952B99B3E3ED167D38B800873E03EFA699DD048B5BA`。
- Experts `自动保本_v31.00.ex4`：`367856` 字节（体积不作为源码一致性条件）。
- v30.10 面板/基线专项回归：`41/41 OK`。
- v30.10 项目源码与 Experts 副本 SHA256：`8AC66DFD60B779E9A058BB294E3962C220FD8860C8148C250B7BD8E2FA96CB7F`。
- Experts `自动保本_v30.10.ex4`：`356110` 字节（体积不作为源码一致性条件）。
- v30.09 项目源码与 Experts 副本 SHA256：`6D41EA100ADD8A3426B58803F3C14E4D0DF19CC610BC2B27E4F5D6DDBE7E9954`。
- Experts `自动保本_v30.09.ex4`：`355744` 字节（本轮重编译；体积不作为源码一致性条件）。
- v30.08 项目源码与 Experts 副本 SHA256：`F0C630CAA1494301CFC90FBCE41EFBFA7F1940644775C63968AE82D618770D20`。
- Experts `自动保本_v30.08.ex4` 已成功生成；重复编译的产物大小会变化，不作为源码一致性验收条件。
- v30.07 项目源码与 Experts 副本 SHA256：`AF70F6E28E72BB38DD081AFDA12D603D8D03DB93FF75B2E4EB2B9D82C193E897`。
- v30.06 项目源码与 Experts 副本 SHA256：`544C2BE121B3EC04A41C93A58C9DC693CAFF19676C1C9001F89A6AAB0FB7244C`。
- Experts `自动保本_v30.06.ex4`：`337584` 字节。
- v30.05 项目源码与 Experts 副本 SHA256：`2DF2B2AA304A5EC86B0692C891A751A0E66400AA52F89DC61D9842D5B62A7AEA`。
- Experts `自动保本_v30.05.ex4`：`336522` 字节。
- v30.04 项目源码与 Experts 副本 SHA256：`6E87674F4891377F3083137C98AAA03BD24C10E3E4C549CFF053A5A54D9D4639`。
- Experts `自动保本_v30.04.ex4`：`332790` 字节。
- v30.03 项目源码与 Experts 副本 SHA256：`55E04D8E91128D901AFD9FDEC10D50C4E013DF2026BF1A40DCD357809313E418`。
- Experts `自动保本_v30.03.ex4`：`332878` 字节。
- v30.02 SHA256 保持 `A91ACCBB85DA995DD325A7A51D051A41218BDC1BB159427A0BD747AD6B979F90`。
- v30.01 SHA256 保持 `6D809C02BD3F805107010CE6921417BE44E79DF4D934877AA23926247B35B648`。
- v30.00 SHA256 保持 `C932E49E55451658FACEC6882A63D5CA0761608B9F8942F9FD9761A913E0DD7A`。
- v29.1 SHA256 保持 `A0965267C2AD7D1A9A887A5AA0FBCA7EE523B989E8D597D0AD2C98BFC75093CC`。

## 使用中观察

- v30.09 的手机部分平仓继承、交易权限恢复、三档手动平仓等 broker 场景尚未逐项实测。
- 用户决定不以逐项 Demo 验收阻塞后续美化；实际使用中出现问题时再提供截图、ticket 和日志。
- Python 和 MetaEditor 结果只证明静态合同与可编译性，不代表上述 broker 场景已经实测通过。

## 下一动作

在 MT4 导航器中刷新并重新挂载 `canvas-panel-demo-v5`，保持 EA `Panel_Scale_Percent=100`，与浏览器 HTML `75%` 逐页截图对照。优先核对字体包围盒、按钮/卡片边缘和留白；设置页临时输入框也需点开确认字号与命中区同步。
## 2026-07-31 本轮收尾

- [x] 用户最终确认 12 个按钮的指定背景色，且所有彩色按钮文字统一为 `#111318`。
- [x] 红绿模式兼容规则保持：只交换方向相关组合色，按钮文字不变；取消组合保本止盈固定紫色，启动突破固定蓝紫色。
- [x] 专项 `19/19 OK`、全量 Python 回归 `216/216 OK`、`SAFETY_SCAN_OK`；两位置 MetaEditor 均为 `Result: 0 errors, 0 warnings`。
- [x] Canvas 项目与 Experts 源码 SHA256 均为 `F1AD0EDF08D78522616B624D95BE70A62BCAE47CF52D2876BF7178115583C508`，`.ex4` 为 `102974` 字节。
- [x] 正式 `src/自动保本_v31.01.mq4` 未修改，SHA256 仍为 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。

## 2026-07-31 按钮比例收尾

- [x] 提示区默认显示由 `7` 条压缩为 `5` 条，高度 `204px -> 164px`，底部留白仍为 `10px`。
- [x] 主要按钮增高到 `34-36px`，关闭类按钮增高到 `28px`，订单页下半部分卡片间距同步放松。
- [x] HTML v6 默认提示条数和高度同步。
- [x] 专项 `19/19 OK`、全量 `216/216 OK`、`SAFETY_SCAN_OK`，双位置编译均为 `0 errors, 0 warnings`。
- [x] Canvas 两份源码 SHA256 为 `77F1E8C12FB7139A66D1AAF8B7E66DC4A1E75116EBDE2629298EAA77AFE853AD`；正式 v31.01 未修改。

## 2026-07-31 最终 650px 默认像素 1:1 迁移

- [x] 根据用户最终截图口径，把默认设计基准改为 `650 x 1545`；默认运行时不缩放，手动宽高输入后才分别计算横纵倍率并重建 Canvas。
- [x] 三页按钮、卡片、文字、命中区域与临时输入框同步迁移；功能按钮统一为 `51px`，组合功能仍只位于组合保本页。
- [x] `DrawRoundedRect()` 使用 `LineAA()` 直边和四分之一弧线补齐抗锯齿外轮廓，解决切角观感。
- [x] 专项 `16/16 OK`、全量 `220/220 OK`、`SAFETY_SCAN_OK`；正式 v31.01 哈希保持不变。
- [ ] MetaEditor 双位置编译与 Experts 部署：当前被权限系统拒绝，不能复用上一轮日志冒充本轮结果。
- [ ] 用户重新挂载后确认实际 MT4 的三页比例、圆角和手动宽高缩放。自动视觉验收未执行，因为当前无可控制的 MT4 窗口且应用控制策略禁止代为启动交易终端。

## 2026-08-09 MT5 Noto Sans SC 静态字重修正版

- [x] 仅处理 `src/mt5_noto sans sc+inter` 的字体加载；布局、颜色、圆角、按钮比例、事件和交易引擎保持不变。
- [x] 将与 HTML 同源的 `NotoSansSC-VF.ttf` 固定为 400/500/600 三份静态字体，并按文字角色嵌入资源。
- [x] 项目/终端同步、MetaEditor `0 errors, 0 warnings`、MT5 合同测试 `98/98 OK`。
- [x] 新 EX5：`MQL5/Experts/MT5Migration_noto sans sc+inter/AutoBreakeven_v31_02_noto sans sc+inter.ex5`，大小 `902,338` bytes，SHA256 `0CE759146CFF76B5EBA25D10351B906836C77B59B25FDF729B79A88223FB2AB8`。
- [ ] 用户重新挂载独立 EX5 并提供截图，完成真实字形验收。

## 2026-08-09 MT5 Noto Sans SC + MiSans Medium

- [x] 保持已确认的 Noto Sans SC 中文资源与全部 UI 几何不变。
- [x] 仅将 ASCII/数字/英文字体切换为 `MiSans-Medium-UI.ttf`，建立独立变体目录和对象名。
- [x] MetaEditor `0 errors, 0 warnings`；MT5 合同测试 `98/98 OK`。
- [x] 新 EX5：`MQL5/Experts/MT5Migration_noto sans sc+misans medium/AutoBreakeven_v31_02_noto sans sc+misans medium.ex5`，SHA256 `961A49383C3DE37265B3638F24BF1118660166AB483FF4D00C50B129A99FF69F`。
- [ ] 用户重新挂载新变体，确认数字和字母的 MiSans Medium 视觉效果。

## 2026-08-09 MT5 Noto Sans SC + MiSans Medium 可见性诊断

- [x] 保留 Noto 中文、布局、颜色、字号、按钮、事件和交易引擎不变；仅将拉丁字体入口改为系统 `MiSans Medium` 优先、内嵌 `MiSans-Medium-UI.ttf` 后备。
- [x] 独立变体加入一次性 `AB_UI_DIAG` 对象/Canvas 状态日志，核对对象、坐标、尺寸、像素和动态资源是否真实存在。
- [x] 用户截图只显示小红框；已确认 Canvas 对象和像素存在，因此新增 `OBJ_BITMAP_LABEL` 的显式 `OBJPROP_XSIZE/OBJPROP_YSIZE` 同步，防止动态资源绑定后停留在默认标记尺寸。
- [x] MetaEditor：`Result: 0 errors, 0 warnings`；MT5 合同测试：`98/98 OK`。
- [x] 新 EX5 已同步到项目和终端；大小 `369,600` bytes，项目/终端 SHA256：`A6EF24D60E5A36F621D8F1C9AA4B427D4B83768E0605CD325330EFEDB0CFCFD2`。
- [ ] 用户重新挂载该独立 EX5 后提供面板截图或终端 `AB_UI_DIAG` 行；重点核对 `xsize/ysize/bitmap` 是否与 `width/height/resource` 一致。

## 2026-08-09 MT5 Noto Sans SC + MiSans Medium v2（原始基线重建）

- [x] 放弃继续修补旧的 `noto sans sc+misans medium` 故障版本；从原始 `src/mt5/AutoBreakeven_v31_02.mq5` 重新复制建立独立目录。
- [x] 数字、字母和 ASCII 使用内嵌 `MiSans-Medium-UI.ttf`；中文按角色直接加载同源 Noto Sans SC 静态 `Regular/Medium/SemiBold` 子集。
- [x] 混合字符串按 ASCII/中文分段测量和绘制；没有带入旧版本的 `AB_UI_DIAG`、`OBJPROP_XSIZE/YSIZE` 尺寸补丁或其他故障诊断代码。
- [x] 交易引擎与原始 `src/mt5` 基线的非 UI 文件 SHA256 完全一致。
- [x] MetaEditor：`Result: 0 errors, 0 warnings`；MT5 合同测试：`98/98 OK`。
- [x] 新 EX5：`MQL5/Experts/MT5Migration_noto sans sc+misans medium v2/AutoBreakeven_v31_02_noto sans sc+misans medium v2.ex5`，大小 `368,344` bytes，SHA256 `93CEBD4732203602FFE03347DC5BA0555A8FAE957AD9CE779D388B6F3B14BBC0`。
- [ ] 用户重新挂载 v2，确认面板是否完整显示及 MiSans/Noto 字形；旧故障版本保持封存。

## 2026-08-03 MD3 粉彩 Canvas Demo v5

- [x] 新建 `src/canvas-panel-demo-v5.mq4`，保留 v4 的三页布局、等比缩放、内存交互、临时输入框和收起/展开。
- [x] 按最终 HTML v25 实现粉彩色板、45 度纹理、下划线页签、运行徽标、组合页红绿按钮和设置页双色选择框。
- [x] 保持 UI-only 安全边界；未读取订单、未调用交易 API、未访问正式持久状态。
- [x] v5 专项 `19/19 OK`；MetaEditor `Result: 0 errors, 0 warnings`；安全扫描和 `git diff --check` 通过。
- [ ] 用户在真实 MT4 中挂载 `canvas-panel-demo-v5.ex4`，确认三页视觉、纹理、点击和缩放手感。

当前正式 EA `src/自动保本_v31.02.mq4` 与旧 Demo `src/canvas-panel-demo-v4.mq4` 均未修改。全量回归 `256` 项中 `251` 项通过，另 `5` 项因两份既有 v29 HTML 说明书缺失而失败，与 v5 无关。

## 2026-08-04 v5 字体渲染根因修复

- [x] 仅修改 `src/canvas-panel-demo-v5.mq4` 的字体渲染入口和临时输入框字体设置。
- [x] 删除错误的 `CANVAS_FONT_POINT_SCALE` 补偿；保留原有字号角色、坐标、布局、颜色、纹理和交互。
- [x] Canvas `FontSet()` 固定使用 `flags=0`，通过 `Microsoft YaHei` / `Microsoft YaHei Bold` 两个真实字体族选择常规和强调文字。
- [x] 专项 `25/25 OK`；项目和 Experts 均由 MetaEditor 编译为 `0 errors, 0 warnings`；最终交付 EX4 已同步到 Experts。
- [ ] 用户重新挂载 `canvas-panel-demo-v5` 后，以 MT4 实际截图作为最终字体视觉验收。

## 2026-08-04 字重与交互提示字号微调

- [x] Canvas 全部文字角色统一使用 `Microsoft YaHei Bold`；不改字号角色、位置或布局。
- [x] `EA 交互提示` 日志正文由 `10` 调整为 `11`；标题、提示区高度和留白保持不动。
- [x] 专项 `25/25 OK`；项目/Experts 编译均为 `0 errors, 0 warnings`，最终 EX4 已同步。

## 2026-08-04 按钮字重与交互提示再次微调

- [x] 官方 `TextSetFont` flags 不包含 Bold；按钮文字改用 Canvas 双次同色绘制实现加粗，仅作用于按钮文字。
- [x] 交互提示日志正文由 `11` 调整为 `12`，提示区布局保持不变。
- [x] 专项 `25/25 OK`；项目/Experts 编译均为 `0 errors, 0 warnings`，EX4 已同步。
