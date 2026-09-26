# 项目进度

## 2026-09-10 MT5 v32.15 突破阶梯修复候选

- 根因：挂单成交时已经带止损，但突破登记的 `initial_sl_done` 仍为 false；既有止损不需要收紧，因而没有修改请求，也没有完成标记，后续阶梯被阻断。
- 修复：检测已有同等或更好止损后确认初始止损完成，并输出一次 `AB_DIAG breakout initial SL confirmed`。缺少或较弱止损仍走原修改流程。
- 专项测试 `tests/mt5/tester/AutoBreakeven_v32_15_BreakoutSL_Tester.mq5`：旧逻辑 checks=46 / failures=34；修复后 checks=66 / failures=0。覆盖双向、2500 点边界、快速越档、保本衔接及防重复请求。测试拦截交易接口，验证请求与状态，不代表真实经纪商成交。
- 正式 EA 编译日志 `tests/mt5/tester/compile-auto-breakeven-v32-15.log`：0 errors, 0 warnings。源码及 EX5 位于 `src/mt5/AutoBreakeven_v32_15.*`，独立 include 为 `src/mt5_v32_15/include`；已部署当前终端 `Experts/MT5Migration_v32_15`，未替换图表上的 EA。
- 待用户真实图表验收；v32.14 保留为已验收基线。GPT Review Picker 不可用，未完成独立审查交接。

## 2026-08-30 MT5 v32.14 无阶梯组合保本验收通过

- [x] v32.13 已将“多单/空单无阶梯组合保本”从组合保本页按钮接入独立运行时命令、组合快照及持久化状态；不再是仅有 UI 的空操作。
- [x] 无阶梯组合成员在组合活动期间不锁存、不执行普通阶梯；原有未成交触及/待重试会清除，已完成阶梯保留。取消组合后只按取消当刻的行情重判未完成阶梯，不补做暂停期间已经回撤的触及。
- [x] v32.14 已在图表层过滤无阶梯组合成员的普通阶梯 `L1-L10` 线和标签，保留开仓价标注；组合外订单及普通组合不受影响。
- [x] 独立源码与产物：`src\\mt5\\AutoBreakeven_v32_14.mq5` / `AutoBreakeven_v32_14.ex5`，配套 include 树为 `src\\mt5_v32_14\\include`。
- [x] MetaEditor 编译日志 `docs\\compile-auto-breakeven-v32-14-hide-no-ladder-lines.log`：`0 errors, 0 warnings`；MT5 合同测试：`205/205 OK`。
- [x] 用户已完成真实图表验收，确认无阶梯组合保本触发后不再显示对应成员的普通阶梯线，v32.14 成为当前 MT5 验收基线。

## 2026-08-24 MT5 v32.05 自动管理按钮映射验收通过

- [x] 自动管理三档按钮已接入运行时自动保本模式：`M1极值止损`、`开仓价止损`、`关闭`。
- [x] 自动管理按钮不再调用下方一次性手动止损命令；手动设定止损区域保持独立。
- [x] 阶梯止盈开关已接入普通订单阶梯处理门控，并同步按钮状态和交互日志。
- [x] UI 外观、布局及其他交易功能未改动。
- [x] `AutoBreakeven_v32_05.mq5/.ex5` 已同步至项目和当前 MT5 终端 Experts。
- [x] MetaEditor：`0 errors, 0 warnings`；相关 MT5 合同测试：`67/67 OK`。
- [x] 用户实盘验收成功，v32.05 作为当前 MT5 基线。

## 2026-08-24 MT5 v32.04 实盘验收通过

- [x] v32.04 已将 MT5 账本改为当前终端本地 `MQL5\\Files`，不再使用跨终端共享 `FILE_COMMON`。
- [x] 账本按平台、账号、服务器和品种隔离；首次无本地账本时按当前真实持仓和挂单重建。
- [x] 仅在启动以及北京时间每小时 `00`/`30` 分执行全量历史核对；连续两次确认完全结束后删除普通、阶梯、组合状态及关联完成/拒绝记录。
- [x] 用户确认实际交易已恢复正常，v32.04 验收成功。
- [x] 验收快照：11 个普通持仓管理对象、11 个阶梯状态、3 条操作记录，恢复锁已解除。
- [x] MetaEditor：`0 errors, 0 warnings`；MT5 合同测试：`24/24 OK`。
- [x] 新账本路径：`C:\\Users\\85472\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\`。

## 2026-08-10 MT5 UI 基线锁定

- [x] 当前 `noto sans sc+misans medium v2`、HTML 75% 宽度 `563px` 版本已锁定为后续升级基线。
- [x] 备份已创建：`baselines\\mt5\\2026-08-10_noto-sans-sc-misans-medium-v2_html75_width563`。
- [x] 备份包含项目源码树、MT5 终端 Experts 副本和编译日志，63 个文件已设为只读。
- [x] 后续升级入口已记录到 `docs\\mt5-migration\\current-ui-baseline.md`。
- [ ] 后续每次 UI 修改只基于该基线工作目录继续，未提到的项不动。

## 2026-08-10 MT5 v2 tick 闪烁修复候选

- [x] 定位为每 tick 无条件 CCanvas.Resize() 重建动态位图资源。
- [x] 已改为仅在宽高变化时 Resize；普通 tick 不再重建资源。
- [x] MetaEditor 0 errors, 0 warnings；MT5 合同测试 98/98 OK。
- [x] 新候选 EX5 已同步到项目和终端，SHA256：41B7E17BE9921929234F4FFB2FF3623AF6D6AB8A5184F830FF887F5FF5BC1C09。
- [ ] 用户真实 MT5 重挂确认无闪烁；确认前不覆盖只读基线。

## 2026-08-09 MT5 Noto + MiSans v2 原始基线重建

- 用户决定不再修补旧的 `noto sans sc+misans medium` 小红框版本，改为从原始 `AutoBreakeven_v31_02` 重新制作。
- 新项目目录：`src/mt5_noto sans sc+misans medium v2`；新终端目录：`MQL5/Experts/MT5Migration_noto sans sc+misans medium v2`。
- 数字/字母/ASCII：内嵌 `MiSans-Medium-UI.ttf`；中文：同源 Noto Sans SC 静态 400/500/600 子集，按角色直接加载。
- 没有带入旧版本的 `AB_UI_DIAG` 或 `OBJPROP_XSIZE/OBJPROP_YSIZE` 补丁；非 UI 交易引擎文件与 `src/mt5` 基线 SHA256 一致。
- MetaEditor：`0 errors, 0 warnings`；MT5 合同：`98/98 OK`。
- 新 EX5 项目/终端一致：`368,344` bytes，SHA256 `93CEBD4732203602FFE03347DC5BA0555A8FAE957AD9CE779D388B6F3B14BBC0`。
- 当前状态：等待用户移除旧实例、刷新 Navigator、挂载 v2 版本并返回截图。

## 2026-08-09 MT5 Noto + MiSans Medium v2 75% 宽度修复

- [x] 定位右侧空条为 `600px` 画布宽度与 HTML 75%/内部设计 `563px` 坐标不一致。
- [x] v2 项目与终端源的 `Panel_Default_Width` 已改为 `563`；其他 UI 与交易代码未动。
- [x] MetaEditor `0 errors, 0 warnings`；MT5 合同测试 `98/98 OK`。
- [x] EX5 已从终端编译产物同步回项目，项目/终端 SHA256 一致：`FB5E1281634B486966ED671D3BA066336EC754377D4FEF8FB06930D37F0BDE88`。
- [ ] 用户重新挂载 v2 截图确认右侧空条消失。

## 2026-08-09 MT5 Noto + MiSans 面板不可见

- 用户反馈 `AutoBreakeven_v31_02_noto sans sc+misans medium.ex5` 挂载后只显示一个小红框。
- 终端 `AB_UI_DIAG` 已证明 Canvas 对象、资源名和像素缓冲存在；问题优先定位为 `OBJ_BITMAP_LABEL` 显示尺寸/资源绑定，而不是字体字形本身。
- 已在独立 MiSans 变体中显式同步 `OBJPROP_XSIZE/OBJPROP_YSIZE`，位置覆盖 `Create()` 首次创建和 `ResizeForTab()` 动态刷新；Noto+Inter 可见变体保持不动。
- 编译：`0 errors, 0 warnings`；MT5 合同：`98/98 OK`；项目与终端 EX5 大小 `369,600` bytes，SHA256：`A6EF24D60E5A36F621D8F1C9AA4B427D4B83768E0605CD325330EFEDB0CFCFD2`。
- 当前状态：等待用户移除旧实例、刷新 Navigator、重新挂载该独立 EX5；若仍是小红框，读取新 `AB_UI_DIAG` 中的 `xsize/ysize/bitmap`。

## 2026-08-03 MD3 粉彩 HTML 原型

- 用户反馈 v1 范围错误：预览不应绘制整个 MT4 图表，也不应重构原有面板布局。
- 已以 `docs/mockups/v30-panel-beauty-a-v6.html` 的单面板布局为基准，新增 `docs/mockups/mt4-ea-md3-pastel-v2.html`；仅替换 MD3 粉彩颜色、按钮尺寸/纹理和统一缩放控制，保留原三页、卡片顺序和按钮位置。
- 用户追加要求：面板内不允许上下滚动；v2 已改为内容自然展开、取消 `.content` 内部滚动，默认 70% 等比预览以完整显示面板。
- 用户已确认当前 v2 作为 UI 基准；后续迭代只修改用户明确指定的局部，不重排布局、不替换未指定控件、不覆盖基准文件。
- 本轮按规范仅替换按钮颜色，新增 `docs/mockups/mt4-ea-md3-pastel-v3.html`；基准文件未修改。改动包括未激活透明态、四档阶梯色、加入/退出管理色、取消挂单、立即结算及组合多空按钮颜色。
- 用户指定四级递进色后，新增 `docs/mockups/mt4-ea-md3-pastel-v4.html`；仅将追踪止损/手动平仓四档改为 `#7E57C2`、`#864FC0`、`#8E48BD`、`#9640B9`。
- 本轮新增 `docs/mockups/mt4-ea-md3-pastel-v5.html`；仅加入 1px 纹理线、3px 间距的 45 度亮/暗纹理伪元素，按按钮底色分别应用，未改变按钮颜色、尺寸或位置。
- 用户指定加入/退出管理新配色后，新增 `docs/mockups/mt4-ea-md3-pastel-v6.html`；仅替换两个按钮的背景与文字颜色。
- 用户指定阶梯止盈开关与自动管理按钮纹理后，新增 `docs/mockups/mt4-ea-md3-pastel-v7.html`；仅将开关改为 `#AE9BF5`，并将自动管理当前按钮纹理改为 `#715CA7` 亮色斜纹。
- 根据截图反馈，新增 `docs/mockups/mt4-ea-md3-pastel-v8.html`；仅修复自动管理按钮纹理覆盖文字的问题，改用按钮背景图层并隐藏该按钮的伪元素纹理。
- 参考用户提供的 `C:\Users\85472\Pictures\md3.html`，新增 `docs/mockups/mt4-ea-md3-pastel-v9.html`；仅统一三页字体为 Inter，并按 md3.html 覆盖各按钮文字颜色。
- 用户追加要求字号对齐 `md3.html`，新增 `docs/mockups/mt4-ea-md3-pastel-v10.html`；仅覆盖标题、卡片、数据、按钮、输入框、设置项和提示文字的字号，未改颜色或布局。
- 用户反馈预览文字比 `md3.html` 偏细，新增 `docs/mockups/mt4-ea-md3-pastel-v11.html`；仅按 md3.html 对齐 400/500/600 字重，未改字号、颜色或布局。
- 用户要求先统一观察效果，新增 `docs/mockups/mt4-ea-md3-pastel-v12.html`；将所有按钮文字统一为 `font-weight: 600`。
- 用户指出加入/退出管理纹理与 `md3.html` 不一致，新增 `docs/mockups/mt4-ea-md3-pastel-v13.html`；仅将两个按钮的纹理改为 `rgba(0,0,0,0.04)` 暗纹理。
- 用户要求三项局部调整，新增 `docs/mockups/mt4-ea-md3-pastel-v14.html`：将“触发下一阶止盈”移入手动平仓卡片；三页签改为 `#AE9BF5` 下划线模式；运行中 Badge/指示灯按 `md3.html` 样式重做。
- 用户指出 v14 越界修改了表头排版；当前预览已恢复到 v13，撤销 v14 的三项改动，历史文件保留但不作为当前版本。
- 用户要求表头管理订单计数改为单行左右两组，新增 `docs/mockups/mt4-ea-md3-pastel-v15.html`；仅调整 counts 的 HTML 与横向布局。
- 用户要求运行指示灯改为图示圆角方框样式，新增 `docs/mockups/mt4-ea-md3-pastel-v16.html`；仅调整 `.live` 的背景、边框、圆角、文字和指示点颜色。
- 用户确认当前设计并要求锁定后，新增 `docs/mockups/mt4-ea-md3-pastel-v17.html`；仅将表头三页签改为透明下划线模式，高亮线颜色 `#AE9BF5`。
- 用户反馈页签下划线不显示且切换位置漂移，新增 `docs/mockups/mt4-ea-md3-pastel-v18.html`；仅补齐页签伪元素 `content`、相对定位和居中布局。
- 用户确认切换组合保本仍漂移，新增 `docs/mockups/mt4-ea-md3-pastel-v19.html`；定位为不同页面高度触发 body 垂直居中，改为顶部固定预览锚点。
- 用户提供对比截图后确认仍有表头高度变化，新增 `docs/mockups/mt4-ea-md3-pastel-v20.html`；定位为面板 Grid 的 auto 行在 min-height 下伸展，加入 `align-content: start` 固定行高度。
- 用户确认进入组合保本页修正，新增 `docs/mockups/mt4-ea-md3-pastel-v21.html`；仅将四个多空按钮改为指定红/绿背景及纹理色。
- 用户更正组合保本按钮色值，新增 `docs/mockups/mt4-ea-md3-pastel-v22.html`；仅替换为绿色 `#7CBF9E/#75B495`、红色 `#E07A8A/#D37382`。
- 用户要求设置页红绿切换按钮改版，新增 `docs/mockups/mt4-ea-md3-pastel-v23.html`；两个按钮同时显示红绿方向，取消紫色填充，选中项使用 `#AE9BF5` 高亮边框。
- 用户指定普通订单 `普X` 标签新颜色，新增 `docs/mockups/mt4-ea-md3-pastel-v24.html`；仅改为背景/边框 `#E5DDF5`、文字 `#2B233D`。
- 用户要求移动“触发下一阶止盈”，新增 `docs/mockups/mt4-ea-md3-pastel-v25.html`；仅将按钮移入手动平仓卡片并置于整单平仓下方。
- 已按本地《MT4 EA面板-MD3粉彩版开发规范》新增 `docs/mockups/mt4-ea-md3-pastel-v1.html`。
- 原型沿用 `v31.02` 三页结构，采用 `550px` 设计宽度、24px 外边距、16px 卡片内边距、12px 控件间距和统一等比缩放。
- 已加入午夜蓝底、粉彩紫/薄荷绿/珊瑚红/加入退出专用色、按钮对角纹理、订单页/组合页/设置页演示状态。
- 已启动本地可视化预览：`http://localhost:56755`；浏览器验证三页切换、缩放滑块和设置页打开，浏览器错误日志为空。
- 当前仅为 HTML 视觉原型，不连接 MT4、不读取订单、不执行交易；下一步等待用户视觉反馈后再进入 Canvas Demo。

日期：2026-08-01

## 当前状态

- 当前产品候选为 `src/自动保本_v31.02.mq4`，已部署到当前 EC Markets MT4 `Experts`；v31.01 保持只读哈希基线。
- v31.02 已用 Canvas 完全替换旧原生三页面板；静态卡片/按钮由 Canvas 绘制，动态统计、选择、组合状态和最近 5 条提示由不可选透明 Label 更新。
- Canvas 点击已接入原有真实动作 key；数值输入只临时创建一个 `OBJ_EDIT`；200ms 按压反馈、三页切换和最小化/恢复已接入正式生命周期。
- `普N/突N` 后缀已改为价格差：BUY=`Bid-OpenPrice`，SELL=`OpenPrice-Ask`，精度跟随 `Digits`，与手数和 `OrderProfit()` 无关。
- “阶梯止盈”开关已加入 Canvas 双事件去重：同一单击只执行一次，不再出现关闭后立即重新开启。
- v31.02 专项 `17/17 OK`、全量回归 `237/237 OK`；项目与 Experts MetaEditor 均为 `0 errors, 0 warnings`。
- 项目与 Experts v31.02 SHA256 均为 `701D86C9378DF8AB1AB2BA033DB83A967A4FE2248076D134F4FBD579D09E4CE4`；Experts `.ex4` 为 `462884` 字节。
- v31.02 正式迁移规格和实施计划已经用户确认并完成自检；下一步进入实现，v31.01 保持只读。
- 新订单标注规则已确认：BUY=`Bid-OpenPrice`，SELL=`OpenPrice-Ask`，跟随品种 `Digits`，不使用手数或 `OrderProfit()`。
- 正式 UI 采用 Canvas 静态层加透明动态文字层；普通价格和数字变化不重绘整张 Canvas，按钮结构状态变化时只重绘一次。
- 用户已确认先把独立 MT4 Canvas 三页演示完整做完并实机验收，再迁移正式 EA；本阶段不修改 v31.01，也不因 UI 迁移 MT5。
- `src/canvas-panel-demo-v4.mq4` 保留 `650 x 1545` 绘制参考坐标，默认实际尺寸已改为等比例的 `600 x 1426`；使用单 `CCanvas`、固定模拟数据和内存点击区域，没有订单读取、正式持久状态或交易 API。本轮已部署到 MT4 `Experts`。
- v4 已完成 `订单操作 / 组合保本 / 设置` 三页。组合页支持模式切换和按模式禁用输入；设置页使用一个临时 `OBJ_EDIT` 完成数值输入。
- `自动保本 / 运行中 / XAUUSD.c` 共用同一视觉中心线；版本小字保持 `V31.01`；当前选择三个指标框高度为 `64px`。
- 用户已确认三页排版与后两个页签结构无需再改；v4 所有按钮现按 HTML v6 一一使用对应填充色、文字色和彩色边框，四档快捷按钮为四个确定的蓝紫实色。
- `docs/mockups/v30-panel-color-pool-v2.html` 已提供 12 个命令按钮的独立背景色和黑/白文字选择；公共色库为 63 色，不再使用组合色板联动。
- v4 顶栏已增加最小化按钮；收起后重建为 `390 x 90` 恢复条，展开后保留原活动页和内存设置。
- 彩色快捷按钮使用填充同色描边；四分之一圆弧改用浮点 `PixelSetAA()` 密集采样，删除旧亮色描边函数。
- 当前专项 `16/16 OK`、项目全量回归 `220/220 OK`，安全扫描通过；项目与 Experts MetaEditor 均为 `0 errors, 0 warnings`。
- 项目与 Experts v4 源码 SHA256 均为 `B969E86B42DF71F9DADF02F76E178407C698B89520AD6902AC6AD616985E6727`，Experts `.ex4` 为 `105826` 字节；正式 v31.01 哈希保持 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。
- v31.01 现作为正式迁移前只读基线，SHA256 为 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`。
- v31.00 首次实机截图确认面板与 HTML 差距过大；根因是 MT4 默认凹陷矩形边框及旧版紧凑布局结构残留。
- v31.01 显式使用平面卡片，重做页面内边距、卡片间距、按钮/字体比例、顶部状态、主要功能卡、双向突破区和交互提示区。
- v31.01 继续沿用 `AB30T. / AB30B.` 交易持久状态；关键阶梯、组合、ticket 迁移与手动平仓函数已与 v31.00 做函数体等价合同。
- v31.01 专项 `5/5 OK`、项目全量回归 `177/177 OK`；项目与 Experts 编译均为 `Result: 0 errors, 0 warnings`。
- 项目与 Experts v31.01 SHA256 均为 `2F73EA77882E21542A09A907E2E4EB84CC3AF9946735695402B30BE8356A1F1A`；Experts `.ex4` 为 `371100` 字节。v31.00 哈希未变。
- v30.10 把双向突破标题和三个按钮从订单页内容流移到独立底部区，只在订单操作页显示，并使用 `PanelLogTop()` 固定锚定于交互提示区上方。
- v30.10 面板/基线专项 `41/41 OK`、项目全量回归 `166/166 OK`；项目与 Experts 编译均为 `Result: 0 errors, 0 warnings`。
- 项目与 Experts v30.10 SHA256 均为 `8AC66DFD60B779E9A058BB294E3962C220FD8860C8148C250B7BD8E2FA96CB7F`；Experts `.ex4` 为 `356110` 字节，体积不作为源码一致性条件。v30.09 哈希保持不变。
- v30.09 已将普通订单严格 lineage 恢复前置到 `IsNormalManagedOrder()` 过滤之前；只有唯一且有 broker comment 明确关联的后继票才迁移。
- v30.09 已增加 `平仓 X% / 平仓 Y% / 整单平仓`，默认 `5/10`，按保存的原始手数向下规整；失败按 tick/200ms 重试，活动按钮可取消，任务不跨重载。
- v30.09 在 `IsTradeAllowed()==false` 时不写入新的阶梯触及，权限恢复后只按当前 BUY Bid / SELL Ask 重新判断；旧 pending 保留。
- 订单页已按自动管理、手动设定止损、追踪止损、手动平仓、触发下一阶、双向突破排列；`普N/突N` 均显示两位 `OrderProfit`，突破票可选中用于手动平仓。
- v30.09 专项回归 `74/74 OK`，全量 Python 回归 `164/164 OK`；项目与 Experts 编译均为 `Result: 0 errors, 0 warnings`。
- 项目与 Experts v30.09 SHA256 均为 `6D41EA100ADD8A3426B58803F3C14E4D0DF19CC610BC2B27E4F5D6DDBE7E9954`；Experts `.ex4` 本轮重编译后为 `355744` 字节，体积不作为源码一致性条件。
- v30.08 已在第二家 broker 复现普通人工受管单的外部部分平仓漏迁移。订单链为 `141144973 -> 141145756 -> 141146377 -> 141146830`；前两次由 EA 发起并成功迁移，手机把 `141146377` 平 `0.10` 手后生成的 `141146830` 显示为未管理。
- 用户人工加入 `141146830` 后，EA 将余仓 `0.30` 手错误视为新的 100%，再次执行 `0.01/0.16` 两档；该结果与新原始仓位按比例向下规整完全吻合。
- 根因不是 lineage 缺失：broker 历史注释明确提供 `to #新ticket / from #旧ticket`。根因是普通后继票没有新 ticket 所有权、又保留启动前原始开仓时间，因此在进入 `FindUniqueRolloverState()` 前被 `IsNormalManagedOrder()` 拒绝。
- 下一版采用最小顺序修正：对看似未管理的普通市价票先尝试唯一可信 lineage 迁移，成功转移状态和所有权后再执行普通管理过滤；不增加无备注猜票。
- 新增手动平仓功能、交易权限关闭期间不锁存新阶梯、面板重排和盈亏标签均已进入当前计划；面板美化明确后置。
- 手动平仓失败将持续重试；活动按钮运行时改为取消命令，另外两个平仓按钮暂时不可用。待重试任务不跨 EA 重载或 MT4 重启恢复。
- Windows WER 只记录到 `terminal.exe 4.0.0.1471` 的 `AppHangTransient`；当天 MQL4 日志约 `72KB/767行`，当前没有证据证明打开日志卡死由 EA 代码导致。
- v30.07 现场复现：Windows 休眠期间从手机端新开的普通 `1.00` 手订单，在电脑恢复后被自动登记，并持续打印 L1 部分平仓失败 `4109/0`。
- 误接管根因是休眠不重新执行 `OnInit()`，旧版只按最初 `EA_StartTime` 判断新旧订单；`4109` 是交易不被允许，不是手数错误，`0` 是请求未发送时读取空错误状态。
- v30.08 将超过 60 秒的 tick 执行空窗视为 EA 未连续观察：空窗中新建且无可信状态/所有权的普通订单保持 `未管理`；已有可信受管单与突破单继续恢复。
- v30.08 的阶梯平仓在 ticket 闸门或 `IsTradeAllowed()` 未通过时保持待重试，每 5 秒最多提示一次，不再记录虚假失败。
- v30.06 现场复现：突破单 L1-L8 已完成后，用户手动部分平仓 `0.50` 手，剩余 `1.50` 手的新 ticket 被当作全新突破单，再次执行 8 档。
- 根因是旧版 ticket 迁移仅接受 EA 自己发起的部分平仓；人工部分平仓没有 `.A=awaitingRollover` 标记，因此未加载旧票的完成状态。
- v30.07 已新增严格的外部部分平仓继承：只有 broker comment 明确关联新旧 ticket，且订单关键字段一致、旧票已关闭、当前手数小于原始仓位时才迁移。
- 迁移继续复用既有完整状态加载和 ticket 替换，保留原始手数、8 档完成/触及状态、显示编号、所有权、手动 SL 状态和组合成员身份。
- v30.08 及更早版本均保持原哈希，v30.08 继续作为冻结实现基线。
- 实施计划 Task 1-12 已完成。正式三页签面板已接入，旧散落按钮 UI 和旧 UI 参数已删除。
- v30.00 首次上机发现三项问题：页签内容纵向过挤；设置面板下半部分显示英文变量/枚举；单击 `未管理` 后面板详情和“加入管理”按钮不刷新。
- v30.01 已改为按可用面板高度增加纵向间距；为相关 input/enum 补中文显示说明；在第一次对象单击事件内重建面板选择区。
- v30.01 第二次上机确认：重建面板后，紧随订单对象点击的重复 `CHARTEVENT_CLICK` 清空了刚建立的选择；旧自动纵向间距最大只有 `16px`，仍不够疏朗。
- v30.02 对订单对象单击后的重复图表事件增加一次性 `500ms` 过滤；之后正常单击空白仍清除选择。
- v30.02 新增 `Panel_Page_Vertical_Spacing` 输入，默认 `24px`、范围 `0-40px`；默认面板参数为左上角、X/Y `10/120`、宽高 `500/1150`。
- 用户已现场确认 v30.02 的订单单击选择修复有效；剩余 UI 问题是标题/页签、页签/首块和选择文字/管理按钮使用固定坐标，不随间距参数变化。
- v30.03 已将这三处接入现有 `Panel_Page_Vertical_Spacing`，没有增加第二套参数，也没有修改交易逻辑。
- v30.04 将统计行、页签和三个页面起点改为累计读取同一运行时间距，并在设置页“面板位置、大小与间距”增加 `页面纵向间距` 编辑框。
- v30.04 项目源码已同步到 MT4 `Experts`，并生成 `自动保本_v30.04.ex4`。
- v30.04 项目源码与 Experts 副本 SHA256 均为 `6E87674F4891377F3083137C98AAA03BD24C10E3E4C549CFF053A5A54D9D4639`。
- v30.05 专项回归为 `29/29 OK`，项目全量 Python 回归为 `143/143 OK`。
- v30.05 项目与 Experts 两份 MetaEditor 日志均为 `Result: 0 errors, 0 warnings`。
- v30.05 项目源码与 Experts 副本 SHA256 均为 `2DF2B2AA304A5EC86B0692C891A751A0E66400AA52F89DC61D9842D5B62A7AEA`；Experts `.ex4` 为 `336522` 字节。
- v30.08 基线/启动恢复/所有权/集成专项为 `41/41 OK`，项目全量 Python 回归为 `151/151 OK`。
- v30.08 项目与 Experts 两份 MetaEditor 日志均为 `Result: 0 errors, 0 warnings`。
- v30.08 项目源码与 Experts 副本 SHA256 均为 `F0C630CAA1494301CFC90FBCE41EFBFA7F1940644775C63968AE82D618770D20`；Experts `.ex4` 已成功生成，大小不作为一致性验收条件。
- v30.07 SHA256 保持 `AF70F6E28E72BB38DD081AFDA12D603D8D03DB93FF75B2E4EB2B9D82C193E897`。
- v30.06 SHA256 保持 `544C2BE121B3EC04A41C93A58C9DC693CAFF19676C1C9001F89A6AAB0FB7244C`。
- v30.03 SHA256 保持 `55E04D8E91128D901AFD9FDEC10D50C4E013DF2026BF1A40DCD357809313E418`。
- v30.02 SHA256 保持 `A91ACCBB85DA995DD325A7A51D051A41218BDC1BB159427A0BD747AD6B979F90`。
- v30.01 SHA256 保持 `6D809C02BD3F805107010CE6921417BE44E79DF4D934877AA23926247B35B648`。
- v30.00 SHA256 保持 `C932E49E55451658FACEC6882A63D5CA0761608B9F8942F9FD9761A913E0DD7A`。
- v29.1 SHA256 保持 `A0965267C2AD7D1A9A887A5AA0FBCA7EE523B989E8D597D0AD2C98BFC75093CC`。
- `docs/v30-demo-checklist.md` 现有 22 个真实 MT4 demo 场景；第 19-22 项复测 v30.09 新增行为。

## 当前阻塞

代码、测试、编译和部署无阻塞。v5 已按 HTML 75% 的 `563px` 屏幕基准同步到当前 MT4 Experts；剩余项是用户在真实 MT4 中完成逐页截图验收，该项不能由静态合同或 MetaEditor 编译代替。

## 下一动作

1. 在 MT4 导航器中刷新并重新加载 `canvas-panel-demo-v5`，设置 `Panel_Scale_Percent=100`。
2. 浏览器保留 HTML `75%`，按订单操作、组合保本、设置三页分别截图对照。
3. 核对面板宽 `563px`、三页高度、按钮/卡片边缘、留白、字体包围盒和基线。
4. 在设置页点开一个临时输入框，确认字号、位置和命中区同步。
5. 若有偏差，只记录具体元素和像素差，不扩大修改范围。

## 恢复说明

继续时依次读取：

1. `docs/project-memory.md`
2. `docs/current-plan.md`
3. `docs/superpowers/plans/2026-08-04-canvas-panel-demo-v5-html75-pixel-parity.md`
4. `tests/fixtures/canvas-panel-demo-v5-html75-metrics.json`
5. `docs/findings.md`
6. `docs/task-log-2026-08-04.md`
7. `docs/v30-demo-checklist.md`

当前 UI 验收候选是 `src/canvas-panel-demo-v5.mq4`；正式 `src/自动保本_v31.02.mq4` 与旧 `src/canvas-panel-demo-v4.mq4` 保持冻结。

## 2026-08-04 思源黑体字体试验候选

- 逐字符 Arial/微软雅黑分流已因实机文字缩小、发糊和拥挤而撤销；v5 当前改用 `Microsoft YaHei UI` 整串测量与绘制，Arial 为后备。
- 字号按 CSS 像素到 Canvas 点值的 `4/3` 比例统一校正，未改任何页面几何或视觉色彩。
- 新 MQ4/EX4 已同步到当前 MT4 Experts；下一步重新挂载 v5，对照 HTML 确认字形是否更接近。
## 2026-07-31 本轮完成

- 用户已确认 12 个按钮的最终背景色，所有彩色按钮文字统一为 `#111318`。
- Canvas v4、颜色池 v2 与测试已同步；专项 `19/19 OK`，全量 `216/216 OK`，安全扫描通过。
- 项目与 Experts 编译均为 `Result: 0 errors, 0 warnings`；Canvas 源码 SHA256 为 `F1AD0EDF08D78522616B624D95BE70A62BCAE47CF52D2876BF7178115583C508`。
- 正式 `v31.01` 未修改，仍等待用户继续实机观察 Canvas 演示；正式迁移必须新建版本。

## 2026-07-31 按钮与提示区比例调整

- Canvas v4 默认显示最近 `5` 条提示，提示区高度为 `164px`；主要功能按钮已增高至 `34-36px`。
- 订单页追踪止损、手动平仓和双向突破卡片已利用释放出的 40px 增加间距。
- 专项 `19/19 OK`、全量 `216/216 OK`、安全扫描通过；双位置编译均为 `0 errors, 0 warnings`。
- 已部署到当前 MT4 Experts；源码 SHA256 为 `77F1E8C12FB7139A66D1AAF8B7E66DC4A1E75116EBDE2629298EAA77AFE853AD`。
- 下一动作：重新加载 Canvas v4，返回订单操作页截图确认纵向比例。

## 2026-07-31 650px 默认像素迁移待编译

- 默认设计坐标为 `650 x 1545`，默认不换算；仅在 input 缩放或设置页手动改宽高后计算倍率。
- 三页功能按钮统一为 `51px`；卡片、文字、命中区域和临时输入框已同步迁移，组合操作继续只在组合保本页。
- 专项 `16/16 OK`、全量 `220/220 OK`、安全扫描通过；Canvas 项目源码 SHA256 为 `028FA8696BE9A1DFB49E5FCC7B166B9850301B57AE0A0A07D21EF8B2875764E1`。
- MetaEditor 启动请求被权限系统拒绝，旧日志未更新，因此本轮尚未完成项目/Experts 编译和部署。
- 下一动作：用户明确授权 MetaEditor 与 Experts 写入后完成编译部署，再重新挂载截图确认；正式 v31.01 仍未修改。

## 2026-08-03 MD3 粉彩 Canvas Demo v5 已生成

- 新增 `src/canvas-panel-demo-v5.mq4` 与编译产物 `src/canvas-panel-demo-v5.ex4`，未部署到 MT4 Experts。
- Demo 仅绘制 Canvas UI、维护模拟状态和内存交互；交易 API 与正式状态前缀安全扫描为 `SAFETY_SCAN_OK`。
- 最终 HTML v25 的色板、纹理、下划线页签、运行徽标、组合页红绿按钮和设置页双色选择样式已映射到 Canvas。
- v5 专项 `19/19 OK`；MetaEditor 日志为 `Result: 0 errors, 0 warnings`；`git diff --check` 通过。
- 全量回归共 `256` 项：`251` 项通过，`5` 项因工作区缺失两份 v29 HTML 说明书而失败；没有 v5 失败。
- 下一动作：在真实 MT4 中挂载 v5 EX4，检查订单操作、组合保本、设置三页的视觉和点击反馈。正式 `v31.02` 与旧 v4 未修改。

## 2026-08-03 v5 纹理修复

- 仅修改 v5 纹理绘制：移除直接写入 Canvas 的半透明 ARGB 和纹理 `LineAA()`。
- 新增不透明 RGB 预混合：深纹理按黑色 10/255 alpha、亮纹理按白色 15/255 alpha 与按钮底色先计算，再用普通 `Line()` 绘制。
- 新 EX4 已覆盖同步到当前 MT4 `MQL4\Experts`，正式 EA 与 v4 未修改。
- v5 专项 `20/20 OK`，MetaEditor `Result: 0 errors, 0 warnings`，安全扫描和 `git diff --check` 通过。
- 下一动作：用户重新挂载 v5，确认加入/退出、手动止损、快捷档位、平仓和突破按钮的纹理与文字是否恢复清晰。

## 2026-08-03 v5 字体对齐

- 仅调整 v5 的字体族、字号和字重：中文 Canvas 优先使用 `Microsoft YaHei UI`，强调/按钮使用 600，普通说明保持常规字重。
- 按最终 HTML 角色统一标题 20px、卡片标题 14px、辅助文字 11px、指标值 13px、状态/日志 11/9px；输入框显示与临时编辑框统一 13px。
- v5 专项测试 `21/21 OK`；MetaEditor `Result: 0 errors, 0 warnings`。
- 新 EX4 已同步至当前 MT4 Experts；项目与 Experts SHA256 均为 `A1A44A497653A5C892D99660EAB0BAC386E20B17EE7CCA5D08AAEB3DD68B5FEB`。
- 未修改颜色、纹理、布局、按钮位置、交互逻辑、正式 EA 或 v4 Demo；下一步仅需用户在 MT4 重新挂载确认视觉。

## 2026-08-03 v5 最终 HTML 字体数值复核

- 对照实机与 HTML 截图确认：旧实现把 CSS 字重 `500/600` 误传给 `CCanvas::FontSet()` 的 `flags` 参数，导致字体渲染与预期不一致。
- 已改用系统现有的 `Noto Sans SC`、`Noto Sans SC Medium`、`Noto Sans SC SemiBold` 三个真实字体族，所有 Canvas 字体 flags 固定为 `0`。
- 浏览器 `computed style` 复核了最终 HTML 的末尾覆盖规则，上一轮误把主标题、卡片标题、说明、指标和按钮字号下调；已恢复为 HTML 实测值：主标题 `20px`、卡片标题 `14px`、卡片说明 `11px`、方向/订单标签/状态 `12px`、统计标签/数值 `11/13px`、按钮 `13px`、阶梯说明 `11px`。
- 保留正确的 Canvas 字体 API 修复：`Noto Sans SC`、`Noto Sans SC Medium`、`Noto Sans SC SemiBold`，`FontSet` flags 固定为 `0`；没有修改布局、坐标、颜色、纹理、尺寸、交互或正式 EA。
- v5 专项测试 `21/21 OK`；项目与 Experts MetaEditor 日志均为 `Result: 0 errors, 0 warnings`。
- 项目与 Experts MQ4 SHA256：`C5818A406319ED31F3FDE7BB5611C9EAAA36C377A6FDEC85201AA3603B85F952`；最终 EX4 已同步，两份 EX4 SHA256：`0B93B64B07E1638E23C3AB4C45253BC095FE4AED2228BE467F328124F4383A0E`。
- 待验收：用户在 MT4 重新挂载 v5，对照 HTML 截图确认字体视觉比例；浏览器 Inter 与 MT4 本地字体的抗锯齿差异仍需实机判断。

## 2026-08-04 字体 API 修复完成

- 已移除错误的 `4/3` 字号补偿，且不再把 CSS 字重值传给 `CCanvas::FontSet()` 的 flags 参数。
- 现用 `Microsoft YaHei` / `Microsoft YaHei Bold` 的真实字体族表达常规与强调字形，Canvas flags 恒为 `0`。
- 验证：v5 专项 `25/25 OK`；项目和 Experts 编译日志均为 `Result: 0 errors, 0 warnings`；最终项目/Experts MQ4 SHA256 均为 `4F233D41162BF858D162712DBCFA285E52E2EC57AD8A677797159AE66E195798`，EX4 SHA256 均为 `19C6DA4C8A54331AD5E48CEF3677B71434674666F26FF45A28BFD55E5F744B77`。
- 下一步：用户重新挂载 `canvas-panel-demo-v5`，只核对字体视觉；有偏差时按具体元素继续限定范围。

## 2026-08-04 字重与提示字号微调完成

- 已统一 Canvas 文字为 `Microsoft YaHei Bold`，日志正文字号为 `11`。
- 验证：专项 `25/25 OK`；项目/Experts MetaEditor 均 `Result: 0 errors, 0 warnings`。
- 项目/Experts MQ4 SHA256：`866A506E7FF3B4AF5E6FC5F0D97F2589E120E52F4666D525B3AEBA36B1A508C6`；EX4 SHA256：`030965CA6F8F82AA2CF9E1F3FC24E080C19DC6022F690469FDCA5BF76796ECEC`。
- 下一步：用户重新挂载 v5，确认文字粗细和交互提示可读性。

## 2026-08-04 按钮字重与提示字号微调完成

- 按钮文字已通过 `DrawButtonTextBold()` 双次绘制加粗；交互提示正文为 `12`。
- 项目与 Experts MQ4 SHA256：`3148411D1472E4D36AC8B589695E31552AA7483E094B5923F7E5058907E50DC0`；EX4 SHA256：`CD00ABC88627DB62F57EFB0AE97F89543B6AC69AFBDDCAA5C551D55A5A189E48`。
- 下一步：移除并重新挂载 v5，核对按钮笔画和日志可读性。

## 2026-08-09 HTML 字体实证完成

- [x] 修正 Chrome 探针的项目路径参数引用和 `file://` URL 编码；独立有界面 Chrome 可稳定连接 CDP。
- [x] 通过 `CSS.getPlatformFontsForNode` 确认中文实际使用 `Noto Sans SC`，英文/数字实际使用 Google Fonts `Inter`。
- [x] 通过 Windows Fonts 注册表确认 `Noto Sans SC` 对应 `C:\\Windows\\Fonts\\NotoSansSC-VF.ttf`；排除雅黑 UI、Arial、MiSans 作为 HTML 实际中文 glyph 字体。
- [x] 本轮未修改 MT5 EA 源码、资源、编译产物或部署目录。
- [ ] 等用户确认后，再建立独立 `Noto Sans SC + Inter` MT5 对照变体；不得覆盖现有 MiSans/Arial 变体。

## 2026-08-09 MT5 Noto Sans SC 字体身份修正版

- [x] 旧可变字体版本因 MT5 `FontSet` 资源加载失败被判定为字体身份不一致，不再作为验收文件。
- [x] 独立变体改用同源 Noto Sans SC 静态 400/500/600 资源；`AB_CanvasPanel` 按角色选择资源并取消雅黑回退。
- [x] 新 EX5 已同步至 `MQL5/Experts/MT5Migration_noto sans sc+inter`，大小 `902,338` bytes，项目/终端 SHA256 一致：`0CE759146CFF76B5EBA25D10351B906836C77B59B25FDF729B79A88223FB2AB8`。
- [x] MetaEditor `0 errors, 0 warnings`；MT5 合同测试 `98/98 OK`。
- [ ] 用户挂载新独立 EX5 后截图确认字形；未确认前不宣称 HTML 视觉已完成。

## 2026-08-09 MT5 Noto Sans SC + MiSans Medium 变体

- [x] 复制当前已确认的 Noto 中文版为独立 `noto sans sc+misans medium` 变体。
- [x] 仅将数字、字母和 ASCII 字符改为 `MiSans-Medium-UI.ttf`；中文 Noto 资源保持不变。
- [x] 新 EX5 已同步至 `MQL5/Experts/MT5Migration_noto sans sc+misans medium`，项目/终端 SHA256 一致：`961A49383C3DE37265B3638F24BF1118660166AB483FF4D00C50B129A99FF69F`。
- [x] MetaEditor `0 errors, 0 warnings`；MT5 合同测试 `98/98 OK`。
- [ ] 用户挂载新独立 EX5 后确认拉丁字形；当前 Noto+Inter 版本不变。
