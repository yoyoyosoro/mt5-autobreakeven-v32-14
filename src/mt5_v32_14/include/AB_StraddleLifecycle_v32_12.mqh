#ifndef AB_STRADDLE_LIFECYCLE_V32_12_MQH
#define AB_STRADDLE_LIFECYCLE_V32_12_MQH

#include "AB_Runtime.mqh"

bool AB_IsStraddlePendingOrderTypeV32_12(const ENUM_ORDER_TYPE order_type)
  {
   return order_type==ORDER_TYPE_BUY_STOP ||
          order_type==ORDER_TYPE_SELL_STOP ||
          order_type==ORDER_TYPE_BUY_LIMIT ||
          order_type==ORDER_TYPE_SELL_LIMIT ||
          order_type==ORDER_TYPE_BUY_STOP_LIMIT ||
          order_type==ORDER_TYPE_SELL_STOP_LIMIT;
  }

bool AB_HasLiveBreakoutOrderV32_12(const string chart_symbol,
                                   const long breakout_magic)
  {
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=chart_symbol ||
         (long)OrderGetInteger(ORDER_MAGIC)!=breakout_magic)
         continue;
      ENUM_ORDER_TYPE order_type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(AB_IsStraddlePendingOrderTypeV32_12(order_type))
         return true;
     }
   return false;
  }

bool AB_HasLiveBreakoutPositionV32_12(const string chart_symbol,
                                      const long breakout_magic)
  {
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket) &&
         PositionGetString(POSITION_SYMBOL)==chart_symbol &&
         (long)PositionGetInteger(POSITION_MAGIC)==breakout_magic)
         return true;
     }
   return false;
  }

ulong AB_StraddlePlacementTicketV32_12(const ulong state_ticket,
                                       const ulong operation_id,
                                       AB_OperationLedger &ledger)
  {
   if(state_ticket!=0)
      return state_ticket;
   AB_OperationRecord operation;
   if(operation_id!=0 && ledger.Get(operation_id,operation))
      return operation.order_ticket;
   return 0;
  }

bool AB_StraddleOrderHistoryFinalV32_12(const ulong order_ticket)
  {
   if(order_ticket==0 || OrderSelect(order_ticket) || !HistoryOrderSelect(order_ticket))
      return false;
   ENUM_ORDER_STATE order_state=(ENUM_ORDER_STATE)HistoryOrderGetInteger(order_ticket,ORDER_STATE);
   return order_state==ORDER_STATE_FILLED ||
          order_state==ORDER_STATE_CANCELED ||
          order_state==ORDER_STATE_REJECTED ||
          order_state==ORDER_STATE_EXPIRED;
  }

bool AB_StraddlePlacementHistoryFinalV32_12(const AB_StraddleState &state,
                                            AB_OperationLedger &ledger)
  {
   bool buy_final=!state.buy_placed;
   if(state.buy_placed)
     {
      ulong ticket=AB_StraddlePlacementTicketV32_12(state.buy_order_ticket,
         state.buy_pending_operation_id,ledger);
      buy_final=AB_StraddleOrderHistoryFinalV32_12(ticket);
     }
   bool sell_final=!state.sell_placed;
   if(state.sell_placed)
     {
      ulong ticket=AB_StraddlePlacementTicketV32_12(state.sell_order_ticket,
         state.sell_pending_operation_id,ledger);
      sell_final=AB_StraddleOrderHistoryFinalV32_12(ticket);
     }
   return buy_final && sell_final;
  }

bool AB_StraddleCanFinalizeFromFactsV32_12(const AB_STRADDLE_PHASE phase,
                                           const bool placement_history_final,
                                           const bool has_live_order,
                                           const bool has_live_position,
                                           const bool has_inflight_operation)
  {
   bool lifecycle_phase=phase==AB_STRADDLE_PLACING || phase==AB_STRADDLE_ACTIVE;
   return lifecycle_phase && placement_history_final &&
          !has_live_order && !has_live_position && !has_inflight_operation;
  }

void AB_ClearStraddleCycleFieldsV32_12(AB_StraddleState &state)
  {
   state.entity_id.value=0;
   state.phase=AB_STRADDLE_NONE;
   state.buy_order_ticket=0;
   state.sell_order_ticket=0;
   state.filled_position_identifier=0;
   state.buy_placed=false;
   state.sell_placed=false;
   state.opposite_cancel_pending=false;
   state.rollback_pending=false;
   state.actual_fill_price=0.0;
   state.buy_pending_operation_id=0;
   state.sell_pending_operation_id=0;
   state.rollback_operation_id=0;
  }

void AB_MarkStraddleDoneV32_12(AB_StraddleState &state)
  {
   AB_ClearStraddleCycleFieldsV32_12(state);
   state.entity_id.value=0;
   state.phase=AB_STRADDLE_DONE;
   state.buy_order_ticket=0;
   state.sell_order_ticket=0;
   state.filled_position_identifier=0;
   state.opposite_cancel_pending=false;
   state.buy_pending_operation_id=0;
   state.sell_pending_operation_id=0;
  }

void AB_PrepareStraddleCycleV32_12(AB_StraddleState &state,
                                   const AB_ManagedEntityId &entity_id)
  {
   AB_ClearStraddleCycleFieldsV32_12(state);
   state.entity_id=entity_id;
   state.phase=AB_STRADDLE_PLACING;
  }

bool AB_TryFinalizeStraddleFromFactsV32_12(AB_StraddleState &state,
                                           AB_OperationLedger &ledger,
                                           const bool placement_history_final,
                                           const bool has_live_order,
                                           const bool has_live_position)
  {
   bool has_inflight_operation=ledger.HasInFlightForEntity(state.entity_id);
   if(!AB_StraddleCanFinalizeFromFactsV32_12(state.phase,placement_history_final,
      has_live_order,has_live_position,has_inflight_operation))
      return false;
   AB_ManagedEntityId cycle_entity=state.entity_id;
   AB_ManagedEntityId buy_order_entity;
   buy_order_entity.value=state.buy_order_ticket;
   AB_ManagedEntityId sell_order_entity;
   sell_order_entity.value=state.sell_order_ticket;
   ledger.RemoveByEntity(cycle_entity);
   if(buy_order_entity.value!=0)
      ledger.RemoveByEntity(buy_order_entity);
   if(sell_order_entity.value!=0)
      ledger.RemoveByEntity(sell_order_entity);
   AB_MarkStraddleDoneV32_12(state);
   return true;
  }

bool AB_ReconcileStraddleLifecycleV32_12(AB_StraddleState &state,
                                         AB_OperationLedger &ledger,
                                         const string chart_symbol,
                                         const long breakout_magic)
  {
   if(state.phase!=AB_STRADDLE_PLACING && state.phase!=AB_STRADDLE_ACTIVE)
      return false;
   bool placement_history_final=AB_StraddlePlacementHistoryFinalV32_12(state,ledger);
   bool has_live_order=AB_HasLiveBreakoutOrderV32_12(chart_symbol,breakout_magic);
   bool has_live_position=AB_HasLiveBreakoutPositionV32_12(chart_symbol,breakout_magic);
   return AB_TryFinalizeStraddleFromFactsV32_12(state,ledger,placement_history_final,
      has_live_order,has_live_position);
  }

AB_CommandResponse AB_StartStraddleV32_12(AB_StraddleState &state,
                                           AB_OperationLedger &ledger,
                                           const AB_SymbolRules &rules,
                                           const MqlTick &tick,
                                           const AB_ManagedEntityId &entity_id,
                                           const string symbol,
                                           const long magic,
                                           const double requested_volume,
                                           const int distance_micro_points,
                                           const int initial_sl_micro_points,
                                           const int slippage_micro_points,
                                           const ulong state_version)
  {
   if(state.phase!=AB_STRADDLE_NONE && state.phase!=AB_STRADDLE_DONE)
      return AB_RejectCommand(AB_ERROR_CONFLICT,state_version);
   if(AB_HasLiveBreakoutOrderV32_12(symbol,magic) ||
      AB_HasLiveBreakoutPositionV32_12(symbol,magic))
      return AB_RejectCommand(AB_ERROR_CONFLICT,state_version);
   double volume=AB_NormalizeVolumeDown(requested_volume,rules.volume_step);
   if(!AB_IsVolumeUsable(volume,rules))
      return AB_RejectCommand(AB_ERROR_VOLUME_TOO_SMALL,state_version);
   AB_StraddlePrices prices;
   if(!AB_ComputeStraddlePrices(rules,tick,distance_micro_points,prices) ||
      initial_sl_micro_points<=0)
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   double distance=AB_MicroPointDistance(rules,initial_sl_micro_points);
   MqlTradeRequest buy_request;
   MqlTradeRequest sell_request;
   if(!AB_PreparePendingOrderRequest(symbol,ORDER_TYPE_BUY_STOP,volume,
                                     prices.buy_stop_price,prices.buy_stop_price-distance,
                                     magic,slippage_micro_points,buy_request) ||
      !AB_PreparePendingOrderRequest(symbol,ORDER_TYPE_SELL_STOP,volume,
                                     prices.sell_stop_price,prices.sell_stop_price+distance,
                                     magic,slippage_micro_points,sell_request))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   AB_PrepareStraddleCycleV32_12(state,entity_id);
   ulong buy_operation=0;
   AB_TRADE_RESULT_KIND buy_result=AB_TRADE_RESULT_UNKNOWN;
   bool buy_sent=AB_SendTradeRequest(buy_request,ledger,entity_id,volume,buy_operation,buy_result,true);
   if(buy_sent && buy_result!=AB_TRADE_RESULT_REJECTED && buy_result!=AB_TRADE_RESULT_UNKNOWN)
      AB_RecordStraddlePlacementAccepted(state,true,buy_operation);
   ulong sell_operation=0;
   AB_TRADE_RESULT_KIND sell_result=AB_TRADE_RESULT_UNKNOWN;
   bool sell_sent=AB_SendTradeRequest(sell_request,ledger,entity_id,volume,sell_operation,sell_result,true);
   if(sell_sent && sell_result!=AB_TRADE_RESULT_REJECTED && sell_result!=AB_TRADE_RESULT_UNKNOWN)
      AB_RecordStraddlePlacementAccepted(state,false,sell_operation);
   if(!state.buy_placed && !state.sell_placed)
     {
      ledger.RemoveByEntity(entity_id);
      AB_MarkStraddleDoneV32_12(state);
      return AB_RejectCommand(AB_ERROR_REQUEST_UNKNOWN,state_version);
     }
   if(!state.buy_placed || !state.sell_placed)
     {
      state.phase=AB_STRADDLE_ROLLING_BACK;
      state.rollback_pending=true;
     }
   AB_CommandResponse response;
   response.result=AB_COMMAND_PENDING;
   response.operation_id=state.buy_placed ? state.buy_pending_operation_id : state.sell_pending_operation_id;
   response.state_version=state_version;
   response.error=AB_ERROR_NONE;
   return response;
  }

int AB_CancelBreakoutPendingOrdersV32_12(AB_OperationLedger &ledger,
                                         const string chart_symbol,
                                         const long breakout_magic)
  {
   if(!AB_HasLiveBreakoutPositionV32_12(chart_symbol,breakout_magic))
      return 0;
   int submitted=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=chart_symbol ||
         (long)OrderGetInteger(ORDER_MAGIC)!=breakout_magic)
         continue;
      ENUM_ORDER_TYPE order_type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!AB_IsStraddlePendingOrderTypeV32_12(order_type))
         continue;
      AB_ManagedEntityId entity_id;
      entity_id.value=ticket;
      if(ledger.HasInFlightForEntity(entity_id))
         continue;
      MqlTradeRequest request;
      if(!AB_PrepareDeleteOrderRequest(ticket,request))
         continue;
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      if(AB_SendTradeRequest(request,ledger,entity_id,0.0,operation_id,result_kind))
         submitted++;
     }
   return submitted;
  }

#endif
