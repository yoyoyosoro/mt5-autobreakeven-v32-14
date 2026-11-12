#ifndef AB_TRADE_ADAPTER_MQH
#define AB_TRADE_ADAPTER_MQH

#include "AB_Types.mqh"
#include "AB_OperationLedger.mqh"

struct AB_TradeOperationCorrelation
  {
   bool active;
   ulong operation_id;
   ulong position_ticket;
  };

struct AB_UnmatchedTradeDeal
  {
   bool active;
   ulong operation_id;
   ulong deal_ticket;
   ulong order_ticket;
   ulong position_ticket;
   double volume;
  };

AB_TradeOperationCorrelation g_ab_trade_correlations[AB_MAX_OPERATION_RECORDS];
AB_UnmatchedTradeDeal g_ab_unmatched_trade_deals[AB_MAX_OPERATION_RECORDS];

bool AB_RegisterTradeOperationCorrelation(const ulong operation_id,
                                          const ulong position_ticket)
  {
   if(operation_id==0 || position_ticket==0)
      return false;
   int free_index=-1;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
     {
      if(g_ab_trade_correlations[i].active &&
         g_ab_trade_correlations[i].operation_id==operation_id)
        {
         g_ab_trade_correlations[i].position_ticket=position_ticket;
         return true;
        }
      if(!g_ab_trade_correlations[i].active && free_index<0)
         free_index=i;
     }
   if(free_index<0)
      return false;
   g_ab_trade_correlations[free_index].active=true;
   g_ab_trade_correlations[free_index].operation_id=operation_id;
   g_ab_trade_correlations[free_index].position_ticket=position_ticket;
   return true;
  }

void AB_ClearTradeOperationCorrelation(const ulong operation_id)
  {
   if(operation_id==0)
      return;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
      if(g_ab_trade_correlations[i].active &&
         g_ab_trade_correlations[i].operation_id==operation_id)
         g_ab_trade_correlations[i].active=false;
  }

bool AB_BufferUnmatchedDeal(const MqlTradeTransaction &transaction,
                            const ulong operation_id)
  {
   if(transaction.deal==0 || transaction.order==0 ||
      transaction.volume<=0.0)
      return false;
   int free_index=-1;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
     {
      if(g_ab_unmatched_trade_deals[i].active &&
         g_ab_unmatched_trade_deals[i].deal_ticket==transaction.deal)
         return true;
      if(!g_ab_unmatched_trade_deals[i].active && free_index<0)
         free_index=i;
     }
   if(free_index<0)
      return false;
   g_ab_unmatched_trade_deals[free_index].active=true;
   g_ab_unmatched_trade_deals[free_index].operation_id=operation_id;
   g_ab_unmatched_trade_deals[free_index].deal_ticket=transaction.deal;
   g_ab_unmatched_trade_deals[free_index].order_ticket=transaction.order;
   g_ab_unmatched_trade_deals[free_index].position_ticket=transaction.position;
   g_ab_unmatched_trade_deals[free_index].volume=transaction.volume;
   return true;
  }

bool AB_ReplayUnmatchedDeals(const ulong operation_id,
                             const ulong order_ticket,
                             AB_OperationLedger &ledger)
  {
   if(operation_id==0 || order_ticket==0)
      return false;
   bool replayed=false;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
      if(g_ab_unmatched_trade_deals[i].active &&
         g_ab_unmatched_trade_deals[i].order_ticket==order_ticket)
        {
         if(ledger.RecordDealByOrder(order_ticket,g_ab_unmatched_trade_deals[i].volume,
                                     g_ab_unmatched_trade_deals[i].deal_ticket))
            replayed=true;
         g_ab_unmatched_trade_deals[i].active=false;
        }
   return replayed;
  }

void AB_ClearUnmatchedDealsForOperation(const ulong operation_id)
  {
   if(operation_id==0)
      return;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
      if(g_ab_unmatched_trade_deals[i].active &&
         g_ab_unmatched_trade_deals[i].operation_id==operation_id)
         g_ab_unmatched_trade_deals[i].active=false;
  }

// SL/TP modifications are paced globally: the broker throttles bursts of
// modifications, while closes were never throttled in live logs.
#define AB_SLTP_PACING_WINDOW_MS 1000
#define AB_SLTP_PACING_MAX_IN_WINDOW 2
#define AB_SLTP_THROTTLE_PAUSE_MS 1000

struct AB_SLTPPacer
  {
   ulong sent_at[AB_SLTP_PACING_MAX_IN_WINDOW];
   int sent_count;
   ulong pause_until;
  };

AB_SLTPPacer g_ab_sltp_pacer;

bool AB_SLTPPacerAllows(const AB_SLTPPacer &pacer,const ulong now_ms)
  {
   if(now_ms<pacer.pause_until)
      return false;
   int recent=0;
   for(int i=0;i<pacer.sent_count;i++)
      if(now_ms-pacer.sent_at[i]<AB_SLTP_PACING_WINDOW_MS)
         recent++;
   return recent<AB_SLTP_PACING_MAX_IN_WINDOW;
  }

void AB_SLTPPacerRecord(AB_SLTPPacer &pacer,const ulong now_ms)
  {
   if(pacer.sent_count<AB_SLTP_PACING_MAX_IN_WINDOW)
     {
      pacer.sent_at[pacer.sent_count++]=now_ms;
      return;
     }
   int oldest=0;
   for(int i=1;i<pacer.sent_count;i++)
      if(pacer.sent_at[i]<pacer.sent_at[oldest])
         oldest=i;
   pacer.sent_at[oldest]=now_ms;
  }

void AB_SLTPPacerPause(AB_SLTPPacer &pacer,const ulong now_ms)
  {
   ulong until=now_ms+AB_SLTP_THROTTLE_PAUSE_MS;
   if(until>pacer.pause_until)
      pacer.pause_until=until;
  }

// The strategy tester has no broker throttling and runs faster than real time.
bool AB_SLTPPacingActive(void)
  {
   return MQLInfoInteger(MQL_TESTER)==0;
  }

void AB_NoteThrottleRetcode(const uint retcode)
  {
   if(retcode==TRADE_RETCODE_TOO_MANY_REQUESTS && AB_SLTPPacingActive())
      AB_SLTPPacerPause(g_ab_sltp_pacer,GetTickCount64());
  }

bool AB_TradingAllowed(void)
  {
   if(MQLInfoInteger(MQL_TESTER)!=0)
      return true;
   return TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)!=0 &&
          MQLInfoInteger(MQL_TRADE_ALLOWED)!=0;
  }

bool g_ab_trading_block_logged=false;

bool AB_PreparePositionSLTPRequest(const string symbol,
                                   const ulong position_ticket,
                                   const double target_sl,
                                   const double current_tp,
                                   MqlTradeRequest &request)
  {
   if(symbol=="" || position_ticket==0 || target_sl<=0.0)
      return false;
   ZeroMemory(request);
   request.action=TRADE_ACTION_SLTP;
   request.symbol=symbol;
   request.position=position_ticket;
   request.sl=target_sl;
   request.tp=current_tp;
   return true;
  }

bool AB_PreparePositionTPRequest(const string symbol,
                                 const ulong position_ticket,
                                 const double current_sl,
                                 const double target_tp,
                                 MqlTradeRequest &request)
  {
   if(symbol=="" || position_ticket==0 || target_tp<0.0)
      return false;
   ZeroMemory(request);
   request.action=TRADE_ACTION_SLTP;
   request.symbol=symbol;
   request.position=position_ticket;
   request.sl=current_sl;
   request.tp=target_tp;
   return true;
  }

bool AB_PreparePositionCloseRequest(const string symbol,
                                    const ulong position_ticket,
                                    const ENUM_POSITION_TYPE position_type,
                                    const double volume,
                                    const MqlTick &tick,
                                    const int slippage_micro_points,
                                    MqlTradeRequest &request)
  {
   if(symbol=="" || position_ticket==0 || volume<=0.0)
      return false;
   ZeroMemory(request);
   request.action=TRADE_ACTION_DEAL;
   request.symbol=symbol;
   request.position=position_ticket;
   request.volume=volume;
   request.type=position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price=position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask;
   request.deviation=(ulong)MathMax(0,slippage_micro_points);
   long filling=(long)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK)!=0)
      request.type_filling=ORDER_FILLING_FOK;
   else if((filling & SYMBOL_FILLING_IOC)!=0)
      request.type_filling=ORDER_FILLING_IOC;
   else
      request.type_filling=ORDER_FILLING_RETURN;
   return request.price>0.0;
  }

bool AB_PrepareDeleteOrderRequest(const ulong order_ticket,
                                  MqlTradeRequest &request)
  {
   if(order_ticket==0)
      return false;
   ZeroMemory(request);
   request.action=TRADE_ACTION_REMOVE;
   request.order=order_ticket;
   return true;
  }

bool AB_PreparePendingOrderRequest(const string symbol,
                                   const ENUM_ORDER_TYPE order_type,
                                   const double volume,
                                   const double price,
                                   const double stop_loss,
                                   const long magic,
                                   const int slippage_micro_points,
                                   MqlTradeRequest &request)
  {
   if(symbol=="" || volume<=0.0 || price<=0.0 || stop_loss<=0.0)
      return false;
   ZeroMemory(request);
   request.action=TRADE_ACTION_PENDING;
   request.symbol=symbol;
   request.type=order_type;
   request.volume=volume;
   request.price=price;
   request.sl=stop_loss;
   request.magic=(ulong)magic;
   request.deviation=(ulong)MathMax(0,slippage_micro_points);
   request.type_time=ORDER_TIME_GTC;
   request.type_filling=ORDER_FILLING_RETURN;
   return true;
  }

AB_TRADE_RESULT_KIND AB_ClassifyTradeRetcode(const uint retcode)
  {
   switch(retcode)
     {
      case TRADE_RETCODE_DONE:
      case TRADE_RETCODE_DONE_PARTIAL:
      case TRADE_RETCODE_PLACED:
      case TRADE_RETCODE_ORDER_CHANGED:
         return AB_TRADE_RESULT_PROCESSING;
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
      case TRADE_RETCODE_PRICE_CHANGED:
      case TRADE_RETCODE_PRICE_OFF:
      case TRADE_RETCODE_TIMEOUT:
      case TRADE_RETCODE_CONNECTION:
      case TRADE_RETCODE_MARKET_CLOSED:
      case TRADE_RETCODE_TRADE_DISABLED:
      case TRADE_RETCODE_LOCKED:
      case TRADE_RETCODE_FROZEN:
      case TRADE_RETCODE_CLOSE_ORDER_EXIST:
      case TRADE_RETCODE_REQUOTE:
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
      case TRADE_RETCODE_SERVER_DISABLES_AT:
         return AB_TRADE_RESULT_TEMPORARY;
      case TRADE_RETCODE_INVALID_STOPS:
      case TRADE_RETCODE_INVALID_FILL:
      case TRADE_RETCODE_INVALID_VOLUME:
      case TRADE_RETCODE_NO_MONEY:
      case TRADE_RETCODE_REJECT:
      case TRADE_RETCODE_CANCEL:
      case TRADE_RETCODE_POSITION_CLOSED:
      // Explicit refusals: the broker did not execute the request.
      case TRADE_RETCODE_INVALID:
      case TRADE_RETCODE_INVALID_PRICE:
      case TRADE_RETCODE_INVALID_EXPIRATION:
      case TRADE_RETCODE_INVALID_ORDER:
      case TRADE_RETCODE_INVALID_CLOSE_VOLUME:
      case TRADE_RETCODE_ONLY_REAL:
      case TRADE_RETCODE_LIMIT_ORDERS:
      case TRADE_RETCODE_LIMIT_VOLUME:
      case TRADE_RETCODE_LIMIT_POSITIONS:
      case TRADE_RETCODE_REJECT_CANCEL:
      case TRADE_RETCODE_LONG_ONLY:
      case TRADE_RETCODE_SHORT_ONLY:
      case TRADE_RETCODE_CLOSE_ONLY:
      case TRADE_RETCODE_FIFO_CLOSE:
      case TRADE_RETCODE_HEDGE_PROHIBITED:
         return AB_TRADE_RESULT_REJECTED;
      default:
         return AB_TRADE_RESULT_UNKNOWN;
     }
  }

// NO_CHANGES means the stops already are where the request wanted them, so a
// stop/target change is done. For any other request it is a plain refusal.
AB_TRADE_RESULT_KIND AB_ClassifyTradeRetcodeForOperation(const uint retcode,
                                                          const AB_OPERATION_PURPOSE purpose)
  {
   if(retcode==TRADE_RETCODE_NO_CHANGES)
      return purpose==AB_PURPOSE_SLTP ? AB_TRADE_RESULT_PROCESSING : AB_TRADE_RESULT_REJECTED;
   return AB_ClassifyTradeRetcode(retcode);
  }

bool AB_SendTradeRequest(MqlTradeRequest &request,
                         AB_OperationLedger &ledger,
                         const AB_ManagedEntityId &entity_id,
                         const double requested_volume,
                         ulong &operation_id,
                         AB_TRADE_RESULT_KIND &result_kind,
                         const bool allow_parallel=false,
                         const bool paced=true)
  {
   result_kind=AB_TRADE_RESULT_UNKNOWN;
   // Nothing is sent or recorded while trading is switched off; callers try
   // again on later ticks once it is allowed.
   if(!AB_TradingAllowed())
     {
      if(!g_ab_trading_block_logged)
         Print("AB_DIAG trading not allowed: requests held until AutoTrading is enabled");
      g_ab_trading_block_logged=true;
      result_kind=AB_TRADE_RESULT_TEMPORARY;
      return false;
     }
   if(g_ab_trading_block_logged)
      Print("AB_DIAG trading allowed again");
   g_ab_trading_block_logged=false;
   AB_OPERATION_PURPOSE purpose=request.action==TRADE_ACTION_SLTP
      ? AB_PURPOSE_SLTP
      : request.action==TRADE_ACTION_REMOVE ? AB_PURPOSE_CANCEL
      : request.action==TRADE_ACTION_PENDING ? AB_PURPOSE_PENDING_ORDER : AB_PURPOSE_CLOSE;
   bool pacing=purpose==AB_PURPOSE_SLTP && AB_SLTPPacingActive();
   ulong now_ms=pacing ? GetTickCount64() : 0;
   // A button click is a single request and is never held back; it still
   // counts toward the window so automatic changes stay paced around it.
   if(pacing && paced && !AB_SLTPPacerAllows(g_ab_sltp_pacer,now_ms))
     {
      result_kind=AB_TRADE_RESULT_TEMPORARY;
      return false;
     }
   if(!ledger.Begin(entity_id,requested_volume,purpose,operation_id,allow_parallel))
     {
      result_kind=AB_TRADE_RESULT_REJECTED;
      return false;
     }
   AB_RegisterTradeOperationCorrelation(operation_id,request.position);
   if(pacing)
      AB_SLTPPacerRecord(g_ab_sltp_pacer,now_ms);

   MqlTradeResult result;
   ZeroMemory(result);
   ResetLastError();
   if(!OrderSendAsync(request,result))
     {
      int error=GetLastError();
      AB_NoteThrottleRetcode(result.retcode);
      result_kind=AB_ClassifyTradeRetcode(result.retcode);
      ledger.SetState(operation_id,result_kind==AB_TRADE_RESULT_TEMPORARY
                      ? AB_OPERATION_TEMPORARY : AB_OPERATION_REJECTED);
      AB_ClearTradeOperationCorrelation(operation_id);
      PrintFormat("AB_DIAG trade send failed operation=%I64u position=%I64u action=%d error=%d retcode=%u comment=%s",
                  operation_id,request.position,(int)request.action,error,result.retcode,result.comment);
      return false;
     }

   ledger.SetRequestId(operation_id,result.request_id);
   ledger.SetOrderTicket(operation_id,result.order);
   AB_NoteThrottleRetcode(result.retcode);
   result_kind=AB_ClassifyTradeRetcodeForOperation(result.retcode,purpose);
   if(result_kind==AB_TRADE_RESULT_TEMPORARY)
     {
      ledger.SetState(operation_id,AB_OPERATION_TEMPORARY);
      AB_ClearTradeOperationCorrelation(operation_id);
     }
   else if(result_kind==AB_TRADE_RESULT_REJECTED)
     {
      ledger.SetState(operation_id,AB_OPERATION_REJECTED);
      AB_ClearTradeOperationCorrelation(operation_id);
     }
   return true;
  }

bool AB_HandleTradeTransaction(const MqlTradeTransaction &transaction,
                               const MqlTradeResult &result,
                               AB_OperationLedger &ledger,
                               AB_OperationRecord &operation)
  {
   ZeroMemory(operation);
   if(transaction.type==TRADE_TRANSACTION_REQUEST && result.request_id!=0)
     {
      if(!ledger.GetByRequest(result.request_id,operation))
         return false;
      if(result.order!=0)
         ledger.SetOrderTicket(operation.operation_id,result.order);
      AB_NoteThrottleRetcode(result.retcode);
      AB_TRADE_RESULT_KIND result_kind=AB_ClassifyTradeRetcodeForOperation(result.retcode,
                                                                           operation.purpose);
      if(result_kind==AB_TRADE_RESULT_TEMPORARY ||
         result_kind==AB_TRADE_RESULT_REJECTED ||
         result_kind==AB_TRADE_RESULT_UNKNOWN)
        {
         if(operation.state==AB_OPERATION_COMPLETED)
           {
            AB_ClearTradeOperationCorrelation(operation.operation_id);
            AB_ClearUnmatchedDealsForOperation(operation.operation_id);
            return true;
           }
         AB_OPERATION_STATE terminal_state=result_kind==AB_TRADE_RESULT_TEMPORARY
            ? AB_OPERATION_TEMPORARY
            : result_kind==AB_TRADE_RESULT_REJECTED
            ? AB_OPERATION_REJECTED : AB_OPERATION_UNKNOWN;
         ledger.SetState(operation.operation_id,terminal_state);
         AB_ClearTradeOperationCorrelation(operation.operation_id);
         AB_ClearUnmatchedDealsForOperation(operation.operation_id);
         ledger.Get(operation.operation_id,operation);
         return true;
        }
      if(!operation.deal_required)
         ledger.RecordPositionUpdate(result.request_id);
      if(!ledger.GetByRequest(result.request_id,operation))
         return false;
      if(operation.deal_required && operation.order_ticket!=0)
        {
         AB_ReplayUnmatchedDeals(operation.operation_id,operation.order_ticket,ledger);
         AB_ClearUnmatchedDealsForOperation(operation.operation_id);
         ledger.GetByRequest(result.request_id,operation);
        }
      if(operation.state==AB_OPERATION_COMPLETED)
        {
         AB_ClearTradeOperationCorrelation(operation.operation_id);
         AB_ClearUnmatchedDealsForOperation(operation.operation_id);
        }
      return true;
     }
   if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0)
      return false;
   if(transaction.volume<=0.0)
      return false;
   if(transaction.order!=0 &&
      ledger.RecordDealByOrder(transaction.order,transaction.volume,transaction.deal) &&
      ledger.GetByOrder(transaction.order,operation))
     {
      if(operation.state==AB_OPERATION_COMPLETED)
        {
         AB_ClearTradeOperationCorrelation(operation.operation_id);
         AB_ClearUnmatchedDealsForOperation(operation.operation_id);
        }
      return true;
     }
   // A position may now have several close requests. Never assign an early deal
   // to the newest request: wait for the request -> order mapping instead.
   ulong operation_id=0;
   int candidates=0;
   for(int i=0;i<AB_MAX_OPERATION_RECORDS;i++)
     {
      if(!g_ab_trade_correlations[i].active ||
         g_ab_trade_correlations[i].position_ticket!=transaction.position) continue;
      AB_OperationRecord candidate;
      if(!ledger.Get(g_ab_trade_correlations[i].operation_id,candidate) ||
         !candidate.deal_required ||
         (candidate.state!=AB_OPERATION_ACCEPTED && candidate.state!=AB_OPERATION_PENDING &&
          candidate.state!=AB_OPERATION_UNKNOWN)) continue;
      operation_id=candidate.operation_id;
      candidates++;
     }
   if(transaction.order!=0)
     {
      if(candidates>0) AB_BufferUnmatchedDeal(transaction,0);
      return false;
     }
   if(candidates!=1) return false;
   AB_OperationRecord pending_operation;
   if(operation_id==0 || !ledger.Get(operation_id,pending_operation) ||
      !pending_operation.deal_required ||
      (pending_operation.state!=AB_OPERATION_ACCEPTED &&
       pending_operation.state!=AB_OPERATION_PENDING &&
       pending_operation.state!=AB_OPERATION_UNKNOWN))
      return false;
   if(transaction.order==0 &&
      ledger.RecordDealByOperation(operation_id,transaction.volume,transaction.deal) &&
      ledger.Get(operation_id,operation))
     {
      if(operation.state==AB_OPERATION_COMPLETED)
        {
         AB_ClearTradeOperationCorrelation(operation.operation_id);
         AB_ClearUnmatchedDealsForOperation(operation.operation_id);
        }
      return true;
     }
   AB_BufferUnmatchedDeal(transaction,operation_id);
   return false;
  }

void AB_HandleTradeTransaction(const MqlTradeTransaction &transaction,
                               const MqlTradeResult &result,
                               AB_OperationLedger &ledger)
  {
   AB_OperationRecord ignored_operation;
   AB_HandleTradeTransaction(transaction,result,ledger,ignored_operation);
  }

#endif
