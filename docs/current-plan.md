# 当前计划

## 当前基线
- v32.16：已验收、实盘运行中（git tag `v32.16`）。

## 当前候选：v32.17（分支 `v32.17`，待实盘验收）
- 部署位置：实盘终端 `MQL5\Experts\AutoBreakeven_v32_17\`；v32.16 未动。
- 内容（均经用户批准）：
  1. 操作记录写满不再卡死：先回收已完成的改 SL/TP 记录；真满时在 EA 交互提示报一次。
  2. 防券商限流：改 SL/TP 全局每秒最多 2 个，被限流再停 1 秒；追踪止损至少前进 5 微点才改（新参数 `Normal_Trail_Min_Step_MicroPoints`，0 = 关闭）。
  3. AutoTrading 关着时不发请求；交易类按钮提示「自动交易未开启」。
  4. 券商明确拒绝按拒绝处理，不锁 EA；改 SL/TP 回「没有变化」算完成。
  5. 「取消挂单」只撤未成交的突破挂单；「立即结算」照旧撤单并平仓。
  6. 止损价按 TickSize 远离现价规整。
  7. 删除 13 个无人调用的旧函数。
- 验收重点：
  - 追踪止损正常跟进，日志里不再出现成串的 `Too many trade requests`。
  - 组合保本一次给多张单挂 TP 时，TP 能陆续全部装上。
  - 突破单成交后点「取消挂单」，已成交的单不被平掉。
- 验收通过后：合并 `main`，打 tag `v32.17`，更新 `docs/progress.md`。

## 版本流程
1. 从 `main` 拉以版本号命名的分支，修改 `AB_EA_VERSION`。
2. 只改本次需求涉及的部分。
3. 验证：MetaEditor `0 errors, 0 warnings`；`tests/mt5/` 合同测试；涉及交易行为时在 `.tester-terminal\` 跑相关 `tests/mt5/tester/` 脚本。
4. 部署到实盘终端 `MQL5\Experts\AutoBreakeven_v32_xx\`，不动正在运行的版本。
5. 用户实盘验收通过后，合并到 `main`，打 tag `v32.xx`，更新 `docs/progress.md`。
