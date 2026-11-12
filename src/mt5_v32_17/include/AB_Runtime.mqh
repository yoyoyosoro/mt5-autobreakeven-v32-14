#ifndef AB_RUNTIME_MQH
#define AB_RUNTIME_MQH

#include "AB_CommandQuery.mqh"
#include "AB_PositionRegistry.mqh"
#include "AB_Persistence.mqh"
#include "AB_NormalEngine.mqh"
#include "AB_LadderEngine.mqh"
#include "AB_StraddleEngine.mqh"
#include "AB_BasketEngine.mqh"
#include "AB_TradeAdapter.mqh"

enum AB_RUNTIME_PHASE
  {
   AB_RUNTIME_RECOVER_UNKNOWN = 0,
   AB_RUNTIME_BREAKOUT_SETTLEMENT,
   AB_RUNTIME_BREAKOUT_MANAGEMENT,
   AB_RUNTIME_BASKET_CLEANUP,
   AB_RUNTIME_BASKET_EXIT,
   AB_RUNTIME_MANUAL_CLOSE,
   AB_RUNTIME_NORMAL_SL,
   AB_RUNTIME_NORMAL_LADDER
  };

struct AB_RuntimeState
  {
   AB_RUNTIME_PHASE last_phase;
   ulong state_version;
   bool recovery_gate;
   bool current_tick_seen;
   bool high_priority_submitted;
  };

bool AB_RuntimeAllowsNewPriceOpportunity(const AB_EngineSnapshot &snapshot)
  {
   return !snapshot.recovery_gate;
  }

bool AB_IsEligibleNormalPosition(const string chart_symbol,
                                 const bool current_symbol_only,
                                 const long normal_magic,
                                 const long straddle_magic,
                                 const datetime runtime_start,
                                 const ulong ticket)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return false;
   string symbol=PositionGetString(POSITION_SYMBOL);
   if(current_symbol_only && symbol!=chart_symbol)
      return false;
   if((long)PositionGetInteger(POSITION_MAGIC)==straddle_magic)
      return false;
   if(normal_magic>=0 && (long)PositionGetInteger(POSITION_MAGIC)!=normal_magic)
      return false;
   datetime open_time=(datetime)PositionGetInteger(POSITION_TIME);
   return open_time>=runtime_start;
  }

int AB_RegisterEligibleNormalPositions(AB_PositionRegistry &registry,
                                        AB_Persistence &persistence,
                                        const string chart_symbol,
                                        const bool current_symbol_only,
                                        const long normal_magic,
                                        const long straddle_magic,
                                        const datetime runtime_start)
  {
   int registered=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(!AB_IsEligibleNormalPosition(chart_symbol,current_symbol_only,normal_magic,
                                       straddle_magic,runtime_start,ticket))
         continue;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(registry.IsRegistered(position_identifier))
         continue;
      AB_ManagedEntityId entity_id;
      entity_id.value=persistence.AllocateEntityId();
      if(registry.Register(entity_id,ticket))
        {
         registered++;
        }
     }
   return registered;
  }

bool AB_IsLaterManagedNormalPosition(const long candidate_time_msc,
                                     const ulong candidate_position_identifier,
                                     const ulong candidate_ticket,
                                     const long latest_time_msc,
                                     const ulong latest_position_identifier,
                                     const ulong latest_ticket)
  {
   if(candidate_time_msc!=latest_time_msc)
      return candidate_time_msc>latest_time_msc;
   if(candidate_position_identifier!=latest_position_identifier)
      return candidate_position_identifier>latest_position_identifier;
   return candidate_ticket>latest_ticket;
  }

bool AB_FindLatestManagedNormalPosition(AB_PositionRegistry &registry,
                                        const string symbol,
                                        AB_PositionLineage &latest)
  {
   bool found=false;
   long latest_time_msc=0;
   ulong latest_position_identifier=0;
   ulong latest_ticket=0;
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;
      ENUM_POSITION_TYPE position_type=
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
         continue;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      ulong ticket=(ulong)PositionGetInteger(POSITION_TICKET);
      if(position_identifier==0 || position_identifier!=lineage.position_identifier ||
         ticket==0)
         continue;
      long time_msc=(long)PositionGetInteger(POSITION_TIME_MSC);
      if(found && !AB_IsLaterManagedNormalPosition(time_msc,position_identifier,ticket,
                                                   latest_time_msc,
                                                   latest_position_identifier,
                                                   latest_ticket))
         continue;
      latest=lineage;
      latest.position_identifier=position_identifier;
      latest.current_ticket=ticket;
      latest_time_msc=time_msc;
      latest_position_identifier=position_identifier;
      latest_ticket=ticket;
      found=true;
     }
   return found;
  }

void AB_RuntimeBeginTick(AB_RuntimeState &runtime,
                         const AB_EngineSnapshot &snapshot)
  {
   runtime.state_version=snapshot.state_version;
   runtime.recovery_gate=snapshot.recovery_gate;
   runtime.current_tick_seen=true;
   runtime.high_priority_submitted=false;
   runtime.last_phase=AB_RUNTIME_RECOVER_UNKNOWN;
  }

bool AB_RuntimeEnterPhase(AB_RuntimeState &runtime,
                          const AB_RUNTIME_PHASE phase,
                          const bool high_priority)
  {
   if(runtime.recovery_gate && phase!=AB_RUNTIME_RECOVER_UNKNOWN)
      return false;
   if(runtime.high_priority_submitted && !high_priority)
      return false;
   runtime.last_phase=phase;
   return true;
  }

bool AB_LoadNormalPositionState(const AB_PositionLineage &lineage,
                                AB_NormalPositionState &position)
  {
   if(!PositionSelectByTicket(lineage.current_ticket))
      return false;
   position.entity_id=lineage.entity_id;
   position.position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   position.current_ticket=lineage.current_ticket;
   position.position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   position.symbol=PositionGetString(POSITION_SYMBOL);
   position.open_time=(datetime)PositionGetInteger(POSITION_TIME);
   position.open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   position.original_volume=lineage.original_volume;
   position.current_volume=PositionGetDouble(POSITION_VOLUME);
   position.current_sl=PositionGetDouble(POSITION_SL);
   position.current_tp=PositionGetDouble(POSITION_TP);
   position.auto_sl_done=lineage.auto_sl_done;
   position.sl_mode=lineage.sl_mode;
   position.trailing_distance_micro_points=lineage.trailing_distance_micro_points;
   return true;
  }

AB_CommandResponse AB_SubmitNormalManualClose(AB_PositionRegistry &registry,
                                              AB_OperationLedger &ledger,
                                              const AB_SymbolRules &rules,
                                              const MqlTick &tick,
                                              const AB_ManagedEntityId &entity_id,
                                              const double ratio_percent,
                                              const bool close_all,
                                              const int slippage_micro_points,
                                              const ulong state_version)
  {
   AB_CommandResponse response=AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
   AB_PositionLineage lineage;
   if(!registry.Get(entity_id,lineage) || !lineage.managed)
      return response;
   if(ledger.HasInFlightForEntity(entity_id))
      return AB_RejectCommand(AB_ERROR_CONFLICT,state_version);
   AB_NormalPositionState position;
   if(!AB_LoadNormalPositionState(lineage,position))
      return response;
   double close_volume=AB_ManualCloseVolume(position,rules,ratio_percent,close_all);
   if(close_volume<=0.0)
      return AB_RejectCommand(AB_ERROR_VOLUME_TOO_SMALL,state_version);
   MqlTradeRequest request;
   if(!AB_PreparePositionCloseRequest(position.symbol,position.current_ticket,
                                       position.position_type,close_volume,tick,
                                       slippage_micro_points,request))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   ulong operation_id=0;
   AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
   if(!AB_SendTradeRequest(request,ledger,entity_id,close_volume,operation_id,result_kind))
      return AB_RejectCommand(AB_ERROR_REQUEST_UNKNOWN,state_version);
   response.result=AB_COMMAND_PENDING;
   response.operation_id=operation_id;
   response.state_version=state_version;
   response.error=AB_ERROR_NONE;
   return response;
  }

bool AB_SubmitNormalSLMode(AB_PositionRegistry &registry,
                           AB_OperationLedger &ledger,
                           const AB_SymbolRules &rules,
                           const MqlTick &tick,
                           const AB_ManagedEntityId &entity_id,
                           const AB_SL_MODE mode,
                           const int distance_micro_points,
                           const int entry_offset_micro_points,
                           const int m1_offset_micro_points)
  {
   if(mode==AB_SL_STOPPED)
      return registry.StopTrailing(entity_id);
   AB_PositionLineage lineage;
   if(!registry.Get(entity_id,lineage) || lineage.auto_sl_pending)
      return false;
   AB_NormalPositionState position;
   if(!AB_LoadNormalPositionState(lineage,position))
      return false;
   double target_sl=0.0;
   bool target_ok=false;
   if(mode==AB_SL_M1)
      target_ok=AB_ComputeM1SL(position,rules,m1_offset_micro_points,target_sl);
   else if(mode==AB_SL_ENTRY)
     {
      target_sl=AB_ComputeEntrySL(position,rules,entry_offset_micro_points);
      target_ok=true;
     }
   else if(mode>=AB_SL_TRAILING_1 && mode<=AB_SL_TRAILING_4)
      target_ok=AB_ComputeTrailingSL(position,rules,tick,distance_micro_points,target_sl);
   if(!target_ok || !AB_IsSLTargetUsable(position,rules,tick,target_sl))
      return false;
   MqlTradeRequest request;
   if(!AB_PreparePositionSLTPRequest(position.symbol,position.current_ticket,target_sl,
                                      position.current_tp,request))
      return false;
   ulong operation_id=0;
   AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
   if(!AB_SendTradeRequest(request,ledger,entity_id,0.0,operation_id,result_kind,false,false))
      return false;
   if(!registry.SetSLMode(entity_id,mode,distance_micro_points))
      return false;
   return registry.MarkSLPending(entity_id,operation_id);
  }

// Trailing positions take turns: with SL changes paced, the scan starts after
// the position that was served last so no position is starved.
int g_ab_trailing_cursor=0;

int AB_ProcessNormalTrailingSL(AB_PositionRegistry &registry,
                               AB_OperationLedger &ledger,
                               const AB_SymbolRules &rules,
                               const MqlTick &tick,
                               const AB_BasketSnapshot &long_basket,
                               const AB_BasketSnapshot &short_basket,
                               const int min_step_micro_points)
  {
   int submitted=0;
   int count=registry.Count();
   int start=count>0 ? g_ab_trailing_cursor%count : 0;
   for(int k=0;k<count;k++)
     {
      int i=(start+k)%count;
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed || lineage.auto_sl_pending ||
         lineage.sl_mode<AB_SL_TRAILING_1 || lineage.sl_mode>AB_SL_TRAILING_4)
         continue;
      if(AB_BasketSuspendsNormalSL(long_basket,lineage.position_identifier) ||
         AB_BasketSuspendsNormalSL(short_basket,lineage.position_identifier))
         continue;
      AB_NormalPositionState position;
      if(!AB_LoadNormalPositionState(lineage,position))
         continue;
      double target_sl=0.0;
      if(!AB_ComputeTrailingSL(position,rules,tick,lineage.trailing_distance_micro_points,target_sl) ||
         !AB_IsSLTightening(position,target_sl) ||
         !AB_TrailingStepReached(position,rules,target_sl,min_step_micro_points) ||
         !AB_IsSLTargetUsable(position,rules,tick,target_sl))
         continue;
      MqlTradeRequest request;
      if(!AB_PreparePositionSLTPRequest(position.symbol,position.current_ticket,target_sl,
                                         position.current_tp,request))
         continue;
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      if(AB_SendTradeRequest(request,ledger,lineage.entity_id,0.0,operation_id,result_kind))
        {
         registry.MarkSLPending(lineage.entity_id,operation_id);
         submitted++;
         g_ab_trailing_cursor=i+1;
        }
     }
   return submitted;
  }

int AB_RearmMissingAutomaticSLState(AB_PositionRegistry &registry,
                                    const AB_BasketSnapshot &long_basket,
                                    const AB_BasketSnapshot &short_basket)
  {
   int rearmed=0;
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed || !lineage.auto_sl_done ||
         lineage.auto_sl_pending || lineage.sl_mode!=AB_SL_NONE)
         continue;
      if(AB_BasketSuspendsNormalSL(long_basket,lineage.position_identifier) ||
         AB_BasketSuspendsNormalSL(short_basket,lineage.position_identifier))
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetDouble(POSITION_SL)>0.0)
         continue;
      if(registry.RearmAutomaticSL(lineage.entity_id))
         rearmed++;
     }
   return rearmed;
  }

int AB_ProcessNormalLadder(AB_PositionRegistry &registry,
                           AB_LadderBook &book,
                           AB_OperationLedger &ledger,
                           const AB_SymbolRules &rules,
                           const MqlTick &tick,
                           const AB_LadderLevelInput &inputs[],
                           const int slippage_micro_points,
                           const AB_BasketSnapshot &long_basket,
                           const AB_BasketSnapshot &short_basket)
  {
   int submitted=0;
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(AB_BasketSuspendsNormalLadder(long_basket,lineage.position_identifier) ||
         AB_BasketSuspendsNormalLadder(short_basket,lineage.position_identifier))
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket))
         continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      double current_volume=PositionGetDouble(POSITION_VOLUME);
      if(!book.Ensure(lineage.entity_id,lineage.original_volume,current_volume,inputs))
         continue;
      AB_LadderPositionState state;
      if(!book.Get(lineage.entity_id,state))
         continue;
      state.current_volume=current_volume;
      state.profit_micro_points=type==POSITION_TYPE_BUY
         ? (tick.bid-open_price)/rules.point
         : (open_price-tick.ask)/rules.point;
      for(int level_index=0;level_index<10;level_index++)
        {
         AB_LadderLevelState level=state.levels[level_index];
         if(!AB_LadderPriceStillTriggered(level,state.profit_micro_points) ||
            ledger.HasInFlightForEntity(lineage.entity_id))
            continue;
         double close_volume=AB_ComputeLadderCloseVolume(state,level,rules);
         if(close_volume<=0.0)
            continue;
         MqlTradeRequest request;
         MqlTick position_tick=tick;
         if(!AB_PreparePositionCloseRequest(lineage.symbol,lineage.current_ticket,type,
                                             close_volume,position_tick,
                                             slippage_micro_points,request))
            continue;
         ulong operation_id=0;
         AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
         if(AB_SendTradeRequest(request,ledger,lineage.entity_id,close_volume,
                                operation_id,result_kind))
           {
            book.MarkPending(lineage.entity_id,level_index,close_volume,operation_id);
            submitted++;
           }
        }
     }
   return submitted;
  }

AB_CommandResponse AB_SubmitNormalNextLadderLevel(AB_PositionRegistry &registry,
                                                  AB_LadderBook &book,
                                                  AB_OperationLedger &ledger,
                                                  const AB_SymbolRules &rules,
                                                  const MqlTick &tick,
                                                  const AB_ManagedEntityId &entity_id,
                                                  const AB_LadderLevelInput &inputs[],
                                                  const int slippage_micro_points,
                                                  const ulong state_version)
  {
   AB_CommandResponse response=AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
   AB_PositionLineage lineage;
   if(!registry.Get(entity_id,lineage) || !lineage.managed)
      return response;
   if(ledger.HasInFlightForEntity(entity_id))
      return AB_RejectCommand(AB_ERROR_CONFLICT,state_version);
   if(!PositionSelectByTicket(lineage.current_ticket))
      return response;

   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   double current_volume=PositionGetDouble(POSITION_VOLUME);
   if(!book.Ensure(lineage.entity_id,lineage.original_volume,current_volume,inputs))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);

   AB_LadderPositionState state;
   if(!book.Get(lineage.entity_id,state))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   state.current_volume=current_volume;
   state.profit_micro_points=type==POSITION_TYPE_BUY
      ? (tick.bid-open_price)/rules.point
      : (open_price-tick.ask)/rules.point;

   int next_level=-1;
   for(int level_index=0;level_index<10;level_index++)
     {
      AB_LadderLevelState level=state.levels[level_index];
      if(level.enabled && !level.completed && !level.pending_request)
        {
         next_level=level_index;
         break;
        }
     }
   if(next_level<0)
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);

   AB_LadderLevelState next=state.levels[next_level];
   double close_volume=AB_ComputeLadderCloseVolume(state,next,rules);
   if(close_volume<=0.0)
      return AB_RejectCommand(AB_ERROR_VOLUME_TOO_SMALL,state_version);

   MqlTradeRequest request;
   if(!AB_PreparePositionCloseRequest(lineage.symbol,lineage.current_ticket,type,
                                       close_volume,tick,slippage_micro_points,request))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);

   ulong operation_id=0;
   AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
   if(!AB_SendTradeRequest(request,ledger,lineage.entity_id,close_volume,
                           operation_id,result_kind))
      return AB_RejectCommand(AB_ERROR_REQUEST_UNKNOWN,state_version);

   book.MarkPending(lineage.entity_id,next_level,close_volume,operation_id);
   response.result=AB_COMMAND_PENDING;
   response.operation_id=operation_id;
   response.state_version=state_version;
   response.error=AB_ERROR_NONE;
   return response;
  }

int AB_RegisterBreakoutPositions(AB_BreakoutRegistry &registry,
                                 AB_Persistence &persistence,
                                 const string chart_symbol,
                                 const long breakout_magic,
                                 const datetime runtime_start)
  {
   int registered=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=chart_symbol ||
         (long)PositionGetInteger(POSITION_MAGIC)!=breakout_magic ||
         (datetime)PositionGetInteger(POSITION_TIME)<runtime_start)
         continue;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      if(registry.IsRegistered(position_identifier))
         continue;
      AB_ManagedEntityId entity_id;
      entity_id.value=persistence.AllocateEntityId();
      if(registry.Register(entity_id,ticket))
        {
         registered++;
        }
     }
   return registered;
  }

bool AB_TradeRequestStillPending(const AB_TRADE_RESULT_KIND result_kind)
  {
   return result_kind==AB_TRADE_RESULT_PROCESSING || result_kind==AB_TRADE_RESULT_UNKNOWN;
  }

bool AB_IsIndependentBreakoutOperation(const AB_OperationRecord &op,AB_BreakoutRegistry &registry)
  {
   if(op.purpose!=AB_PURPOSE_CLOSE && op.purpose!=AB_PURPOSE_SLTP) return false;
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage item;
      if(registry.GetAt(i,item) && item.entity_id.value==op.entity_id.value) return true;
     }
   return false;
  }

bool AB_FirstBlockingUnknownRequest(AB_OperationLedger &ledger,AB_BreakoutRegistry &registry,
                                    ulong &request_id)
  {
   request_id=0;
   for(int i=0;i<ledger.Count();i++)
     {
      AB_OperationRecord op;
      if(!ledger.GetAt(i,op) || op.state!=AB_OPERATION_UNKNOWN || op.request_id==0) continue;
      // Unknown breakout closes retain their volume reservation and per-level
      // lock. They must not prevent other levels from submitting independently.
      if(AB_IsIndependentBreakoutOperation(op,registry)) continue;
      request_id=op.request_id;
      return true;
     }
   return false;
  }

int AB_ReconcileBreakoutClosures(AB_BreakoutRegistry &registry,AB_LadderBook &book,
                                 AB_OperationLedger &ledger)
  {
   int resolved=0;
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage item;
      if(!registry.GetAt(i,item)) continue;
      for(int j=0;j<ledger.Count();j++)
        {
         AB_OperationRecord op;
         if(!ledger.GetAt(j,op) || op.entity_id.value!=item.entity_id.value ||
            op.purpose!=AB_PURPOSE_CLOSE) continue;
         if(op.state==AB_OPERATION_COMPLETED)
           { if(book.CompleteByOperation(op.operation_id)) resolved++; continue; }
         if(op.state==AB_OPERATION_REJECTED || op.state==AB_OPERATION_TEMPORARY)
           { if(book.RejectByOperation(op.operation_id,op.completed_volume)) resolved++; continue; }
         if(op.order_ticket==0 || OrderSelect(op.order_ticket) ||
            !HistoryOrderSelect(op.order_ticket)) continue;
         ENUM_ORDER_STATE state=(ENUM_ORDER_STATE)HistoryOrderGetInteger(op.order_ticket,ORDER_STATE);
         if(state!=ORDER_STATE_FILLED && state!=ORDER_STATE_CANCELED &&
            state!=ORDER_STATE_REJECTED && state!=ORDER_STATE_EXPIRED) continue;
         double expected=HistoryOrderGetDouble(op.order_ticket,ORDER_VOLUME_INITIAL)-
                         HistoryOrderGetDouble(op.order_ticket,ORDER_VOLUME_CURRENT);
         if(!HistorySelectByPosition(item.position_identifier)) continue;
         double filled=0.0;
         for(int k=0;k<HistoryDealsTotal();k++)
           {
            ulong deal=HistoryDealGetTicket(k);
            if(deal!=0 && (ulong)HistoryDealGetInteger(deal,DEAL_ORDER)==op.order_ticket)
               filled+=HistoryDealGetDouble(deal,DEAL_VOLUME);
           }
         // Order and deal notifications can arrive out of order. Do not release
         // a reservation until all executions reported by the order are visible.
         if(filled+1.0e-8<expected) continue;
         ledger.SetConfirmedCloseVolume(op.operation_id,filled,true);
         ledger.Get(op.operation_id,op);
         AB_ClearTradeOperationCorrelation(op.operation_id);
         AB_ClearUnmatchedDealsForOperation(op.operation_id);
         if(op.state==AB_OPERATION_COMPLETED) book.CompleteByOperation(op.operation_id);
         else book.RejectByOperation(op.operation_id,op.completed_volume);
         resolved++;
         PrintFormat("AB_DIAG breakout close reconciled position=%I64u operation=%I64u filled=%.8f requested=%.8f state=%d",
                     item.current_ticket,op.operation_id,op.completed_volume,op.requested_volume,(int)op.state);
        }
     }
   return resolved;
  }

void AB_ReconcileBreakoutSL(AB_BreakoutRegistry &registry,AB_OperationLedger &ledger,
                            const AB_SymbolRules &rules,const int initial_distance,
                            const int lock_distance)
  {
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage item;
      if(!registry.GetAt(i,item) || !item.sl_pending) continue;
      AB_OperationRecord op;
      bool found=ledger.Get(item.pending_operation_id,op);
      if(found && (op.state==AB_OPERATION_REJECTED || op.state==AB_OPERATION_TEMPORARY))
        { registry.RejectSLPending(item.pending_operation_id); continue; }
      if(!PositionSelectByTicket(item.current_ticket)) continue;
      double direction=item.position_type==POSITION_TYPE_BUY ? 1.0 : -1.0;
      double target=AB_AlignStopForPosition(PositionGetDouble(POSITION_PRICE_OPEN)+
                    direction*rules.point*(item.pending_kind==1 ? -initial_distance : lock_distance),
                    rules,item.position_type);
      double sl=PositionGetDouble(POSITION_SL);
      bool applied=sl>0.0 && direction*(sl-target)>=-rules.point*0.1;
      if((found && op.state==AB_OPERATION_COMPLETED) || applied)
        {
         if(found) ledger.SetState(item.pending_operation_id,AB_OPERATION_COMPLETED);
         AB_ClearTradeOperationCorrelation(item.pending_operation_id);
         registry.MarkSLCompleted(item.pending_operation_id);
         PrintFormat("AB_DIAG breakout SL reconciled position=%I64u operation=%I64u",
                     item.current_ticket,item.pending_operation_id);
        }
     }
  }

int AB_ProcessBreakoutLadder(AB_BreakoutLineage &lineage,AB_LadderBook &book,
                             AB_OperationLedger &ledger,const AB_SymbolRules &rules,
                             const MqlTick &tick,const AB_LadderLevelInput &inputs[],
                             const double profit,const int slippage,bool &close_due)
  {
   close_due=false;
   if(!PositionSelectByTicket(lineage.current_ticket) ||
      !book.Ensure(lineage.entity_id,lineage.original_volume,
                   PositionGetDouble(POSITION_VOLUME),inputs)) return 0;
   AB_LadderPositionState state;
   if(!book.Get(lineage.entity_id,state)) return 0;
   state.profit_micro_points=profit;
   int submitted=0;
   for(int level_index=0;level_index<10;level_index++)
     {
      AB_LadderLevelState level=state.levels[level_index];
      if(!AB_LadderPriceStillTriggered(level,profit)) continue;
      if(!PositionSelectByTicket(lineage.current_ticket)) break;
      state.current_volume=ledger.AvailableCloseVolume(lineage.entity_id,
                              PositionGetDouble(POSITION_VOLUME),lineage.original_volume);
      double close_volume=AB_ComputeLadderCloseVolume(state,level,rules);
      if(close_volume<=0.0) continue;
      MqlTradeRequest request;
      if(!AB_PreparePositionCloseRequest(lineage.symbol,lineage.current_ticket,
                    lineage.position_type,close_volume,tick,slippage,request)) continue;
      close_due=true;
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      bool sent=AB_SendTradeRequest(request,ledger,lineage.entity_id,close_volume,
                                    operation_id,result_kind,true);
      if(sent && AB_TradeRequestStillPending(result_kind))
        {
         book.MarkPending(lineage.entity_id,level_index,close_volume,operation_id);
         submitted++;
         PrintFormat("AB_DIAG breakout ladder submitted position=%I64u level=L%d operation=%I64u volume=%.8f profit_points=%.1f",
                     lineage.current_ticket,level_index+1,operation_id,close_volume,profit);
        }
      else if(operation_id!=0)
         PrintFormat("AB_DIAG breakout ladder not accepted position=%I64u level=L%d operation=%I64u result_kind=%d",
                     lineage.current_ticket,level_index+1,operation_id,(int)result_kind);
     }
   return submitted;
  }

int AB_ProcessBreakoutManagement(AB_BreakoutRegistry &registry,
                                 AB_LadderBook &ladder_book,
                                 AB_OperationLedger &ledger,
                                 const AB_SymbolRules &rules,
                                 const MqlTick &tick,
                                 const int initial_sl_micro_points,
                                 const int be_trigger_micro_points,
                                 const int be_lock_micro_points,
                                 const AB_LadderLevelInput &ladder_inputs[],
                                 const int slippage_micro_points)
  {
   int submitted=0;
   AB_ReconcileBreakoutClosures(registry,ladder_book,ledger);
   AB_ReconcileBreakoutSL(registry,ledger,rules,initial_sl_micro_points,be_lock_micro_points);
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket))
         continue;
      AB_NormalPositionState position;
      ZeroMemory(position);
      position.entity_id=lineage.entity_id;
      position.current_ticket=lineage.current_ticket;
      position.position_type=lineage.position_type;
      position.symbol=lineage.symbol;
      position.open_time=(datetime)PositionGetInteger(POSITION_TIME);
      position.open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      position.original_volume=lineage.original_volume;
      position.current_volume=PositionGetDouble(POSITION_VOLUME);
      position.current_sl=PositionGetDouble(POSITION_SL);
      position.current_tp=PositionGetDouble(POSITION_TP);
      double profit_micro_points=lineage.position_type==POSITION_TYPE_BUY
         ? (tick.bid-position.open_price)/rules.point
         : (position.open_price-tick.ask)/rules.point;
      bool close_due=false;
      submitted+=AB_ProcessBreakoutLadder(lineage,ladder_book,ledger,rules,tick,
                           ladder_inputs,profit_micro_points,slippage_micro_points,close_due);
      // Closing is independent of an outstanding SL change. New SL changes
      // remain serialized, so a rally cannot generate a stream of stale changes.
      if(close_due || lineage.sl_pending || ledger.HasInFlightForEntity(lineage.entity_id)) continue;
      // A filled pending order can already carry the required (or better) SL.
      if(!lineage.initial_sl_done && initial_sl_micro_points>0 && position.current_sl>0.0)
        {
         double initial_distance=AB_MicroPointDistance(rules,initial_sl_micro_points);
         double initial_target=AB_AlignStopForPosition(lineage.position_type==POSITION_TYPE_BUY
            ? position.open_price-initial_distance : position.open_price+initial_distance,
            rules,lineage.position_type);
         if(initial_target>0.0 && !AB_IsSLTightening(position,initial_target) &&
            registry.ConfirmExistingInitialSL(lineage.entity_id))
           {
            lineage.initial_sl_done=true;
            PrintFormat("AB_DIAG breakout initial SL confirmed: ticket=%I64u current_sl=%s target_sl=%s",
               lineage.current_ticket,DoubleToString(position.current_sl,rules.digits),
               DoubleToString(initial_target,rules.digits));
           }
        }
      double target_sl=0.0;
      int kind=0;
      if(!lineage.initial_sl_done && initial_sl_micro_points>0)
        {
         double distance=AB_MicroPointDistance(rules,initial_sl_micro_points);
         target_sl=lineage.position_type==POSITION_TYPE_BUY
            ? position.open_price-distance : position.open_price+distance;
         kind=1;
        }
      else if(!lineage.auto_sl_done && be_trigger_micro_points>0 &&
              profit_micro_points>=be_trigger_micro_points)
        {
         double lock=AB_MicroPointDistance(rules,be_lock_micro_points);
         target_sl=lineage.position_type==POSITION_TYPE_BUY
            ? position.open_price+lock : position.open_price-lock;
         kind=2;
        }
      if(kind>0)
         target_sl=AB_AlignStopForPosition(target_sl,rules,lineage.position_type);
      if(kind>0 && AB_IsSLTightening(position,target_sl) &&
         AB_IsSLTargetUsable(position,rules,tick,target_sl))
        {
         MqlTradeRequest request;
         if(AB_PreparePositionSLTPRequest(lineage.symbol,lineage.current_ticket,target_sl,
                                           position.current_tp,request))
           {
            ulong operation_id=0;
            AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
            if(AB_SendTradeRequest(request,ledger,lineage.entity_id,0.0,operation_id,result_kind) &&
               AB_TradeRequestStillPending(result_kind))
              {
               registry.MarkPending(lineage.entity_id,operation_id,kind);
               submitted++;
              }
           }
         continue;
        }
     }
   return submitted;
  }

AB_CommandResponse AB_StartStraddle(AB_StraddleState &state,
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
   state.entity_id=entity_id;
   state.phase=AB_STRADDLE_PLACING;
   state.buy_placed=false;
   state.sell_placed=false;
   state.rollback_pending=false;
   state.buy_order_ticket=0;
   state.sell_order_ticket=0;
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
      state.phase=AB_STRADDLE_DONE;
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

bool AB_IsBreakoutPendingOrderType(const ENUM_ORDER_TYPE order_type)
  {
   return order_type==ORDER_TYPE_BUY_STOP || order_type==ORDER_TYPE_SELL_STOP ||
          order_type==ORDER_TYPE_BUY_LIMIT || order_type==ORDER_TYPE_SELL_LIMIT ||
          order_type==ORDER_TYPE_BUY_STOP_LIMIT || order_type==ORDER_TYPE_SELL_STOP_LIMIT;
  }

// Deletes unfilled breakout pending orders only; filled breakout positions
// stay under management.
int AB_DeleteBreakoutPendingOrders(AB_OperationLedger &ledger,
                                   const string chart_symbol,
                                   const long breakout_magic)
  {
   int submitted=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=chart_symbol ||
         (long)OrderGetInteger(ORDER_MAGIC)!=breakout_magic ||
         !AB_IsBreakoutPendingOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
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

int AB_ProcessStraddleRollback(AB_StraddleState &state,
                               AB_OperationLedger &ledger,
                               const string chart_symbol,
                               const long breakout_magic)
  {
   if(!state.rollback_pending)
      return 0;
   int submitted=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=chart_symbol ||
         (long)OrderGetInteger(ORDER_MAGIC)!=breakout_magic)
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
   bool remaining_orders=false;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket!=0 && OrderGetString(ORDER_SYMBOL)==chart_symbol &&
         (long)OrderGetInteger(ORDER_MAGIC)==breakout_magic)
         remaining_orders=true;
     }
   if(!remaining_orders)
     {
      state.rollback_pending=false;
      state.phase=AB_STRADDLE_DONE;
     }
   return submitted;
  }

int AB_ProcessBreakoutSettlement(AB_StraddleState &state,
                                 AB_BreakoutRegistry &registry,
                                 AB_OperationLedger &ledger,
                                 const AB_SymbolRules &rules,
                                 const MqlTick &tick,
                                 const string chart_symbol,
                                 const long breakout_magic,
                                 const int slippage_micro_points)
  {
   if(state.phase!=AB_STRADDLE_SETTLING)
      return 0;
   int submitted=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=chart_symbol ||
         (long)OrderGetInteger(ORDER_MAGIC)!=breakout_magic)
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
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!registry.GetAt(i,lineage) || !PositionSelectByTicket(lineage.current_ticket))
         continue;
      AB_ManagedEntityId entity_id=lineage.entity_id;
      double volume=ledger.AvailableCloseVolume(entity_id,PositionGetDouble(POSITION_VOLUME),
                                                lineage.original_volume);
      volume=AB_NormalizeVolumeDown(volume,rules.volume_step);
      if(!AB_IsVolumeUsable(AB_NormalizeVolumeDown(volume,rules.volume_step),rules))
         continue;
      MqlTradeRequest request;
      if(!AB_PreparePositionCloseRequest(lineage.symbol,lineage.current_ticket,
                                          lineage.position_type,volume,tick,
                                          slippage_micro_points,request))
         continue;
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      if(AB_SendTradeRequest(request,ledger,entity_id,volume,operation_id,result_kind,true) &&
         AB_TradeRequestStillPending(result_kind))
         submitted++;
     }
   bool remaining_orders=false;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket!=0 && OrderGetString(ORDER_SYMBOL)==chart_symbol &&
         (long)OrderGetInteger(ORDER_MAGIC)==breakout_magic)
         remaining_orders=true;
     }
   bool remaining_positions=false;
   for(int i=0;i<registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(registry.GetAt(i,lineage) && PositionSelectByTicket(lineage.current_ticket))
         remaining_positions=true;
     }
   if(!remaining_orders && !remaining_positions)
      state.phase=AB_STRADDLE_DONE;
   return submitted;
  }

bool AB_CreateBasketSnapshot(AB_PositionRegistry &registry,
                             AB_LadderBook &ladder_book,
                             AB_Persistence &persistence,
                             const AB_SymbolRules &rules,
                             const MqlTick &tick,
                             const string chart_symbol,
                             const ENUM_POSITION_TYPE direction,
                             const AB_BASKET_EXIT_MODE exit_mode,
                             const bool no_ladder,
                             const AB_LadderLevelInput &ladder_inputs[],
                             AB_BasketSnapshot &basket)
  {
   ZeroMemory(basket);
   basket.basket_id.value=persistence.AllocateEntityId();
   basket.phase=AB_BASKET_NONE;
   basket.exit_mode=exit_mode;
   basket.direction=direction;
   basket.symbol=chart_symbol;
   basket.no_ladder=no_ladder;
   basket.frozen_bid=tick.bid;
   basket.frozen_ask=tick.ask;
   basket.frozen_spread=tick.ask-tick.bid;
   basket.frozen_point=rules.point;
   basket.frozen_tick_size=rules.tick_size;
   basket.frozen_tick_value=SymbolInfoDouble(chart_symbol,SYMBOL_TRADE_TICK_VALUE);
   basket.member_count=0;
   basket.ladder_event_count=0;
   basket.frozen_net_result=0.0;
   if(tick.bid<=0.0 || tick.ask<=0.0 || basket.frozen_spread<0.0 ||
      basket.frozen_point<=0.0 || basket.frozen_tick_size<=0.0 ||
      basket.frozen_tick_value<=0.0)
      return false;
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed || lineage.symbol!=chart_symbol ||
         !PositionSelectByTicket(lineage.current_ticket) ||
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)!=direction)
         continue;
      if(basket.member_count>=64)
         return false;
      int member_index=basket.member_count++;
      basket.members[member_index].entity_id=lineage.entity_id;
      basket.members[member_index].position_identifier=lineage.position_identifier;
      basket.members[member_index].volume=PositionGetDouble(POSITION_VOLUME);
      basket.members[member_index].open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      basket.members[member_index].frozen_net_result=
         PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+
         AB_FrozenPositionCommission(lineage.position_identifier);
      basket.members[member_index].active=true;
      basket.members[member_index].combo_sl_suppressed=false;
      if(basket.members[member_index].volume<=0.0 ||
         basket.members[member_index].open_price<=0.0)
         return false;
      basket.frozen_net_result+=basket.members[member_index].frozen_net_result;
      double current_profit_micro_points=direction==POSITION_TYPE_BUY
         ? (tick.bid-basket.members[member_index].open_price)/rules.point
         : (basket.members[member_index].open_price-tick.ask)/rules.point;
      if(!ladder_book.Ensure(lineage.entity_id,lineage.original_volume,
                             basket.members[member_index].volume,ladder_inputs))
            return false;
      if(no_ladder)
        {
         ladder_book.ResetUnfinishedTriggers(lineage.entity_id);
         continue;
        }
      AB_LadderPositionState ladder_state;
         if(!ladder_book.Get(lineage.entity_id,ladder_state))
            return false;
      double simulated_remaining=basket.members[member_index].volume;
      for(int level=0;level<10;level++)
        {
         AB_LadderLevelState level_state=ladder_state.levels[level];
         if(!level_state.enabled || level_state.completed)
            continue;
         ladder_state.current_volume=simulated_remaining;
         double close_volume=AB_ComputeLadderCloseVolume(ladder_state,level_state,rules);
         if(close_volume<=0.0)
            continue;
         if(basket.ladder_event_count>=640)
            return false;
         double target_price=direction==POSITION_TYPE_BUY
            ? basket.members[member_index].open_price+
              AB_MicroPointDistance(rules,level_state.distance_micro_points)
            : basket.members[member_index].open_price-
              AB_MicroPointDistance(rules,level_state.distance_micro_points);
         if(current_profit_micro_points>=level_state.distance_micro_points)
            target_price=direction==POSITION_TYPE_BUY ? tick.bid : tick.ask;
         int event_index=basket.ladder_event_count++;
         basket.ladder_events[event_index].price=target_price;
         basket.ladder_events[event_index].close_volume=close_volume;
         simulated_remaining-=close_volume;
        }
     }
   if(basket.member_count<=0)
      return false;
   AB_SortBasketLadderEvents(basket);
   if(basket.frozen_net_result>=0.0)
      basket.zero_price=direction==POSITION_TYPE_BUY ? tick.bid : tick.ask;
   else if(!AB_ComputeBasketZeroPrice(basket,rules,basket.zero_price))
      return false;
   basket.favorable_extreme=basket.zero_price;
   basket.trailing_paused=false;
   basket.force_close=false;
   basket.phase=AB_BASKET_ACTIVE;
   if(!persistence.Save())
     {
      ZeroMemory(basket);
      return false;
     }
   return true;
  }

ulong AB_FindPositionTicketByIdentifier(const ulong position_identifier)
  {
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==position_identifier)
         return ticket;
     }
   return 0;
  }

bool AB_IsBasketTPUsable(const AB_BasketSnapshot &basket,
                         const AB_SymbolRules &rules,
                         const MqlTick &tick,
                         const double target_tp)
  {
   if(target_tp<=0.0 || rules.point<=0.0)
      return false;
   double distance=basket.direction==POSITION_TYPE_BUY ? target_tp-tick.ask : tick.bid-target_tp;
   return distance>=rules.stops_level_points*rules.point;
  }

int AB_ProcessBasketCancellation(AB_BasketSnapshot &basket,
                                 AB_OperationLedger &ledger,
                                 const AB_SymbolRules &rules,
                                 const MqlTick &tick)
  {
   if(basket.phase!=AB_BASKET_CANCELLING && basket.phase!=AB_BASKET_SWITCHING)
      return 0;
   int submitted=0;
   for(int i=0;i<basket.member_count;i++)
     {
      ulong ticket=AB_FindPositionTicketByIdentifier(basket.members[i].position_identifier);
      if(ticket==0)
        {
         AB_BasketMarkExternalMemberExit(basket,basket.members[i].position_identifier);
         continue;
        }
      if(!basket.members[i].tp_installed || basket.members[i].owned_tp<=0.0 ||
         basket.members[i].pending_operation_id!=0 || !PositionSelectByTicket(ticket))
         continue;
      double current_tp=PositionGetDouble(POSITION_TP);
      if(MathAbs(current_tp-basket.members[i].owned_tp)>AB_Tolerance(rules.tick_size))
        {
         basket.members[i].tp_installed=false;
         continue;
        }
      if(ledger.HasInFlightForEntity(basket.members[i].entity_id))
         continue;
      MqlTradeRequest request;
      if(!AB_PreparePositionTPRequest(basket.symbol,ticket,PositionGetDouble(POSITION_SL),0.0,request))
         continue;
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      if(AB_SendTradeRequest(request,ledger,basket.members[i].entity_id,0.0,operation_id,result_kind))
        {
         AB_BasketMarkOperationPending(basket,i,operation_id,4);
         submitted++;
        }
     }
   bool cleanup_pending=false;
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].active && basket.members[i].tp_installed)
         cleanup_pending=true;
   if(!cleanup_pending)
      basket.phase=AB_BASKET_NONE;
   return submitted;
  }

AB_EngineSnapshot AB_BuildEngineSnapshot(const AB_PositionRegistry &normal_registry,
                                         const AB_BreakoutRegistry &breakout_registry,
                                         const AB_BasketSnapshot &long_basket,
                                         const AB_BasketSnapshot &short_basket,
                                         const ulong state_version,
                                         const bool recovery_gate)
  {
   AB_EngineSnapshot snapshot=AB_EmptyEngineSnapshot(state_version,recovery_gate);
   snapshot.managed_normal_count=normal_registry.ManagedCount();
   snapshot.managed_straddle_count=breakout_registry.ManagedCount();
   snapshot.visible_basket_count=(long_basket.phase!=AB_BASKET_NONE ? 1 : 0)+
                                  (short_basket.phase!=AB_BASKET_NONE ? 1 : 0);
   snapshot.visible_ladder_count=snapshot.managed_normal_count*10+
                                 snapshot.managed_straddle_count*10;
   return snapshot;
  }

AB_CommandResponse AB_JoinManualNormalPosition(AB_PositionRegistry &registry,
                                               AB_LadderBook &ladder_book,
                                               AB_Persistence &persistence,
                                               const AB_SymbolRules &rules,
                                               const MqlTick &tick,
                                               const string symbol,
                                               const long breakout_magic,
                                               const ulong ticket,
                                               const AB_LadderLevelInput &ladder_inputs[],
                                               const ulong state_version)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   if(PositionGetString(POSITION_SYMBOL)!=symbol ||
      (long)PositionGetInteger(POSITION_MAGIC)==breakout_magic)
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   AB_PositionLineage lineage;
   if(registry.GetByPositionIdentifier(position_identifier,lineage))
     {
      if(!registry.SetManaged(lineage.entity_id,true))
         return AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
      registry.RefreshTicket(lineage.entity_id);
     }
   else
     {
      AB_ManagedEntityId entity_id;
      entity_id.value=persistence.AllocateEntityId();
      if(!registry.Register(entity_id,ticket) ||
         !registry.Get(entity_id,lineage))
         return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
     }
   if(!PositionSelectByTicket(ticket))
      return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
   double current_volume=PositionGetDouble(POSITION_VOLUME);
   ladder_book.Ensure(lineage.entity_id,lineage.original_volume,current_volume,
                      ladder_inputs);
   AB_LadderPositionState ladder_state;
   if(ladder_book.Get(lineage.entity_id,ladder_state))
     {
      double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      ladder_state.profit_micro_points=type==POSITION_TYPE_BUY
         ? (tick.bid-open_price)/rules.point
         : (open_price-tick.ask)/rules.point;
     }
   return AB_AcceptCommand(state_version);
  }

AB_CommandResponse AB_ExitNormalManagement(AB_PositionRegistry &registry,
                                           AB_BasketSnapshot &long_basket,
                                           AB_BasketSnapshot &short_basket,
                                           const AB_ManagedEntityId &entity_id,
                                           const ulong state_version)
  {
   AB_PositionLineage lineage;
   if(!registry.Get(entity_id,lineage) || !lineage.managed)
      return AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
   if(!registry.SetManaged(entity_id,false))
      return AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
   AB_BasketMarkExternalMemberExit(long_basket,lineage.position_identifier);
   AB_BasketMarkExternalMemberExit(short_basket,lineage.position_identifier);
   AB_BasketUpdatePhaseAfterMemberExit(long_basket);
   AB_BasketUpdatePhaseAfterMemberExit(short_basket);
   return AB_AcceptCommand(state_version);
  }

AB_CommandResponse AB_ExecuteCommand(const AB_CommandRequest &command,
                                     AB_PositionRegistry &normal_registry,
                                     AB_BreakoutRegistry &breakout_registry,
                                     AB_BasketSnapshot &long_basket,
                                     AB_BasketSnapshot &short_basket,
                                     AB_StraddleState &straddle_state,
                                     AB_LadderBook &normal_ladder_book,
                                     AB_Persistence &persistence,
                                     AB_OperationLedger &ledger,
                                     const AB_SymbolRules &rules,
                                     const MqlTick &tick,
                                     const string symbol,
                                     const long normal_magic,
                                     const long breakout_magic,
                                     const double straddle_lot,
                                     const int straddle_distance,
                                     const int straddle_initial_sl,
                                     const int slippage,
                                     const AB_LadderLevelInput &normal_ladder_inputs[],
                                     const AB_BASKET_EXIT_MODE basket_exit_mode,
                                     const ulong state_version)
  {
   if(persistence.CanIssueNewActions()==false && command.command!=AB_COMMAND_NONE)
      return AB_RejectCommand(AB_ERROR_TEMPORARY_RESTRICTION,state_version);
   if(command.command==AB_COMMAND_JOIN)
      return AB_JoinManualNormalPosition(normal_registry,normal_ladder_book,
                                         persistence,rules,tick,symbol,
                                         breakout_magic,command.position_ticket,
                                         normal_ladder_inputs,state_version);
   if(command.command==AB_COMMAND_EXIT_MANAGEMENT)
      return AB_ExitNormalManagement(normal_registry,long_basket,short_basket,
                                     command.entity_id,state_version);
   if(command.command==AB_COMMAND_SELECT_SL_MODE)
     {
      if(!AB_SubmitNormalSLMode(normal_registry,ledger,rules,tick,command.entity_id,
                                 command.sl_mode,command.distance_micro_points,
                                 command.distance_micro_points,command.distance_micro_points))
         return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
      return AB_AcceptCommand(state_version);
     }
   if(command.command==AB_COMMAND_STOP_TRAILING)
     {
      if(!normal_registry.StopTrailing(command.entity_id))
         return AB_RejectCommand(AB_ERROR_NOT_MANAGED,state_version);
      return AB_AcceptCommand(state_version);
     }
   if(command.command==AB_COMMAND_MANUAL_CLOSE || command.command==AB_COMMAND_EXIT)
      return AB_SubmitNormalManualClose(normal_registry,ledger,rules,tick,command.entity_id,
                                         command.ratio_percent,command.command==AB_COMMAND_EXIT,
                                         slippage,state_version);
   if(command.command==AB_COMMAND_TRIGGER_NEXT_LEVEL)
      return AB_SubmitNormalNextLadderLevel(normal_registry,normal_ladder_book,ledger,
                                            rules,tick,command.entity_id,
                                            normal_ladder_inputs,slippage,
                                            state_version);
   if(command.command==AB_COMMAND_BASKET_LONG || command.command==AB_COMMAND_BASKET_SHORT ||
      command.command==AB_COMMAND_BASKET_LONG_NO_LADDER ||
      command.command==AB_COMMAND_BASKET_SHORT_NO_LADDER)
     {
      bool created=false;
      bool no_ladder=command.command==AB_COMMAND_BASKET_LONG_NO_LADDER ||
                     command.command==AB_COMMAND_BASKET_SHORT_NO_LADDER;
      if(command.command==AB_COMMAND_BASKET_LONG ||
         command.command==AB_COMMAND_BASKET_LONG_NO_LADDER)
         created=AB_CreateBasketSnapshot(normal_registry,normal_ladder_book,persistence,rules,tick,
            symbol,POSITION_TYPE_BUY,basket_exit_mode,no_ladder,normal_ladder_inputs,long_basket);
      else
         created=AB_CreateBasketSnapshot(normal_registry,normal_ladder_book,persistence,rules,tick,
            symbol,POSITION_TYPE_SELL,basket_exit_mode,no_ladder,normal_ladder_inputs,short_basket);
      if(!created)
         return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
      return AB_AcceptCommand(state_version);
     }
   if(command.command==AB_COMMAND_BASKET_CANCEL)
     {
      AB_BasketRequestCancel(long_basket);
      AB_BasketRequestCancel(short_basket);
      return AB_AcceptCommand(state_version);
     }
   if(command.command==AB_COMMAND_STRADDLE_START)
      return AB_StartStraddle(straddle_state,ledger,rules,tick,command.entity_id,symbol,
                              breakout_magic,straddle_lot,straddle_distance,
                              straddle_initial_sl,slippage,state_version);
   if(command.command==AB_COMMAND_STRADDLE_CANCEL_ORDERS)
     {
      AB_DeleteBreakoutPendingOrders(ledger,symbol,breakout_magic);
      return AB_AcceptCommand(state_version);
     }
   if(command.command==AB_COMMAND_STRADDLE_SETTLE)
     {
      AB_RequestStraddleSettlement(straddle_state);
      return AB_AcceptCommand(state_version);
     }
   return AB_RejectCommand(AB_ERROR_INVALID_ARGUMENT,state_version);
  }

#endif
