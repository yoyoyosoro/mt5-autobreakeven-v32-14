# 项目进度

## 当前已验收基线：v32.16
- 用户已在实盘运行并验收 v32.16（v32.15 随之视为已验收）。git tag `v32.16`。
- 相对 v32.15 的改动：
  - 突破持仓的阶梯止盈不再被在途 SL 修改阻挡。
  - 多个突破平仓请求可同时在途，用 `AvailableCloseVolume` 预留手数，不会超平。
  - 成交按 deal ticket 去重；部分成交时该档未成交的差额保持可重试。
  - 突破平仓和 SL 在 250ms 定时器里按订单/成交历史对账。
  - 突破结算只平未预留的手数。
  - LOCKED、FROZEN、CLOSE_ORDER_EXIST、REQUOTE、CLIENT/SERVER_DISABLES_AT 归为暂时性返回码，可重试。
  - 发送失败打印 `AB_DIAG trade send failed` 诊断行。
- 验证证据：
  - MT5 数学模式测试脚本 `tests/mt5/tester/AutoBreakeven_v32_16_ConcurrentExit_Tester.mq5`：84/84 检查通过。
  - MetaEditor：`0 errors, 0 warnings`。
  - 用户实盘验收通过。

## 候选 v32.17：已部署，待实盘验收
- 内容见 `docs/current-plan.md`。
- 验证证据（都不是实盘验证）：
  - 实盘终端 MetaEditor（build 6257）与测试终端（build 6090）编译：`0 errors, 0 warnings`。
  - Python 合同测试：203 项通过。
  - MT5 数学模式测试脚本：
    - `AutoBreakeven_v32_17_Ledger_Tester`：164/164。其中“写满后新请求被拒”在 v32.16 上先复现失败，修复后通过。
    - `AutoBreakeven_v32_16_ConcurrentExit_Tester`：84/84。
    - v32.06 tick 回放、v32.11 组合退出、v32.12 突破周期：全部通过。
    - `AutoBreakeven_v32_15_BreakoutSL_Tester` 按用户确认的规则重写（改 SL 未确认时到价照样发止盈）：118/118，v32.16 原版代码同样 118/118。

## 下一步
- 用户实盘验收 v32.17。
