#ifndef AB_NORMAL_SAFETY_V32_06_MQH
#define AB_NORMAL_SAFETY_V32_06_MQH

#include "AB_Runtime.mqh"

#define AB_MAX_AUTO_SL_TRIGGER_LATCHES 128
#define AB_AUTO_SL_PENDING_TIMEOUT_SECONDS 30

enum AB_AUTO_SL_PENDING_DECISION
  {
   AB_AUTO_SL_PENDING_KEEP = 0,
   AB_AUTO_SL_PENDING_COMPLETE,
   AB_AUTO_SL_PENDING_CLEAR_RETRY
  };

struct AB_AutoSLTriggerLatch
  {
   AB_ManagedEntityId entity_id;
   double best_profit_micro_points;
   ulong trigger_time_msc;
   string last_block_reason;
   datetime last_block_log_time;
  };

bool AB_AutoSLTriggerReachedInTicks(const ENUM_POSITION_TYPE position_type,
                                    const double open_price,
                                    const AB_SymbolRules &rules,
                                    const int trigger_micro_points,
                                    const MqlTick &ticks[],
                                    double &best_profit_micro_points)
  {
   best_profit_micro_points=0.0;
   if(open_price<=0.0 || rules.point<=0.0 || trigger_micro_points<=0)
      return false;
   bool price_seen=false;
   double best=-DBL_MAX;
   for(int i=0;i<ArraySize(ticks);i++)
     {
      double close_price=position_type==POSITION_TYPE_BUY ? ticks[i].bid : ticks[i].ask;
      if(close_price<=0.0)
         continue;
      double profit_micro_points=position_type==POSITION_TYPE_BUY
         ? (close_price-open_price)/rules.point
         : (open_price-close_price)/rules.point;
      if(!price_seen || profit_micro_points>best)
        {
         best=profit_micro_points;
         price_seen=true;
        }
     }
   if(!price_seen)
      return false;
   best_profit_micro_points=best;
   return best+AB_Tolerance(rules.point)/rules.point>=trigger_micro_points;
  }

AB_AUTO_SL_PENDING_DECISION AB_DecideAutoSLPending(
   const bool record_found,
   const AB_OPERATION_STATE operation_state,
   const datetime created_at,
   const datetime now,
   const bool live_sl_present)
  {
   if(live_sl_present)
      return AB_AUTO_SL_PENDING_COMPLETE;
   if(!record_found || operation_state==AB_OPERATION_COMPLETED ||
      operation_state==AB_OPERATION_TEMPORARY ||
      operation_state==AB_OPERATION_REJECTED)
      return AB_AUTO_SL_PENDING_CLEAR_RETRY;
   bool in_flight=operation_state==AB_OPERATION_ACCEPTED ||
                  operation_state==AB_OPERATION_PENDING ||
                  operation_state==AB_OPERATION_UNKNOWN;
   if(in_flight && created_at>0 && now>=created_at &&
      now-created_at>=AB_AUTO_SL_PENDING_TIMEOUT_SECONDS)
      return AB_AUTO_SL_PENDING_CLEAR_RETRY;
   return AB_AUTO_SL_PENDING_KEEP;
  }

bool AB_ShouldKeepAutoSLPending(const AB_TRADE_RESULT_KIND result_kind)
  {
   return result_kind==AB_TRADE_RESULT_PROCESSING ||
          result_kind==AB_TRADE_RESULT_UNKNOWN;
  }

class AB_AutoSLTriggerLatchBook
  {
private:
   AB_AutoSLTriggerLatch m_items[AB_MAX_AUTO_SL_TRIGGER_LATCHES];
   int m_count;

   int Find(const AB_ManagedEntityId &entity_id) const
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==entity_id.value)
            return i;
      return -1;
     }

public:
   AB_AutoSLTriggerLatchBook(void)
     {
      Reset();
     }

   void Reset(void)
     {
      m_count=0;
     }

   bool MarkTriggered(const AB_ManagedEntityId &entity_id,
                      const double best_profit_micro_points,
                      const ulong trigger_time_msc)
     {
      if(entity_id.value==0 || best_profit_micro_points<=0.0)
         return false;
      int index=Find(entity_id);
      if(index<0)
        {
         if(m_count>=AB_MAX_AUTO_SL_TRIGGER_LATCHES)
            return false;
         index=m_count++;
         ZeroMemory(m_items[index]);
         m_items[index].entity_id=entity_id;
        }
      if(best_profit_micro_points>=m_items[index].best_profit_micro_points)
        {
         m_items[index].best_profit_micro_points=best_profit_micro_points;
         m_items[index].trigger_time_msc=trigger_time_msc;
        }
      return true;
     }

   bool IsTriggered(const AB_ManagedEntityId &entity_id,
                    double &best_profit_micro_points,
                    ulong &trigger_time_msc) const
     {
      int index=Find(entity_id);
      if(index<0)
        {
         best_profit_micro_points=0.0;
         trigger_time_msc=0;
         return false;
        }
      best_profit_micro_points=m_items[index].best_profit_micro_points;
      trigger_time_msc=m_items[index].trigger_time_msc;
      return true;
     }

   bool Clear(const AB_ManagedEntityId &entity_id)
     {
      int index=Find(entity_id);
      if(index<0)
         return false;
      for(int i=index;i<m_count-1;i++)
         m_items[i]=m_items[i+1];
      m_count--;
      return true;
     }

   void Prune(AB_PositionRegistry &registry)
     {
      for(int i=m_count-1;i>=0;i--)
        {
         AB_PositionLineage lineage;
         if(registry.Get(m_items[i].entity_id,lineage) && lineage.managed)
            continue;
         for(int j=i;j<m_count-1;j++)
            m_items[j]=m_items[j+1];
         m_count--;
        }
     }

   void LogBlocked(const AB_ManagedEntityId &entity_id,
                   const ulong ticket,
                   const string reason,
                   const string details)
     {
      int index=Find(entity_id);
      if(index<0)
         return;
      datetime now=TimeCurrent();
      if(m_items[index].last_block_reason==reason &&
         now-m_items[index].last_block_log_time<30)
         return;
      m_items[index].last_block_reason=reason;
      m_items[index].last_block_log_time=now;
      Print("AB_DIAG auto-sl blocked reason=",reason,
            " ticket=",ticket,
            " entity=",entity_id.value,
            " peak_micro_points=",DoubleToString(m_items[index].best_profit_micro_points,1),
            " ",details);
     }
  };

int AB_CopyNormalOpportunityTicks(const string symbol,
                                  const MqlTick &current_tick,
                                  ulong &from_msc,
                                  MqlTick &ticks[])
  {
   ArrayResize(ticks,0);
   bool history_ok=false;
   if(symbol!="" && current_tick.time_msc>0)
     {
      if(from_msc==0 || current_tick.time_msc<(long)from_msc)
         from_msc=(ulong)current_tick.time_msc;
      ResetLastError();
      int copied=CopyTicksRange(symbol,ticks,COPY_TICKS_ALL,from_msc,
                                (ulong)current_tick.time_msc);
      history_ok=copied>=0;
      if(copied<0)
        {
         static datetime last_error_log=0;
         datetime now=TimeCurrent();
         if(now-last_error_log>=30)
           {
            last_error_log=now;
            Print("AB_DIAG auto-sl tick replay failed symbol=",symbol,
                  " from_msc=",from_msc,
                  " to_msc=",current_tick.time_msc,
                  " error=",GetLastError());
           }
         ArrayResize(ticks,0);
        }
     }

   int count=ArraySize(ticks);
   bool current_present=count>0 &&
      ticks[count-1].time_msc==current_tick.time_msc &&
      MathAbs(ticks[count-1].bid-current_tick.bid)<=AB_Tolerance(current_tick.bid) &&
      MathAbs(ticks[count-1].ask-current_tick.ask)<=AB_Tolerance(current_tick.ask);
   if(!current_present)
     {
      ArrayResize(ticks,count+1);
      ticks[count]=current_tick;
      count++;
     }
   if(history_ok)
      from_msc=(ulong)current_tick.time_msc;
   return count;
  }

int AB_ReconcileNormalAutoSLPending(AB_PositionRegistry &registry,
                                    AB_OperationLedger &ledger,
                                    AB_AutoSLTriggerLatchBook &latches)
  {
   int resolved=0;
   datetime now=TimeCurrent();
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.auto_sl_pending)
         continue;
      bool live_sl_present=false;
      if(PositionSelectByTicket(lineage.current_ticket) &&
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)==lineage.position_identifier)
         live_sl_present=PositionGetDouble(POSITION_SL)>0.0;
      AB_OperationRecord operation;
      bool record_found=ledger.Get(lineage.pending_operation_id,operation);
      AB_OPERATION_STATE state=record_found ? operation.state : AB_OPERATION_NONE;
      datetime created_at=record_found ? operation.created_at : 0;
      AB_AUTO_SL_PENDING_DECISION decision=AB_DecideAutoSLPending(record_found,
         state,created_at,now,live_sl_present);
      if(decision==AB_AUTO_SL_PENDING_KEEP)
         continue;
      if(decision==AB_AUTO_SL_PENDING_COMPLETE)
        {
         if(record_found)
            ledger.SetState(lineage.pending_operation_id,AB_OPERATION_COMPLETED);
         if(registry.MarkSLCompleted(lineage.entity_id,lineage.pending_operation_id))
           {
            latches.Clear(lineage.entity_id);
            resolved++;
            Print("AB_DIAG auto-sl pending reconciled from live SL ticket=",
                  lineage.current_ticket," entity=",lineage.entity_id.value,
                  " operation=",lineage.pending_operation_id);
           }
         continue;
        }
      if(record_found &&
         (state==AB_OPERATION_ACCEPTED || state==AB_OPERATION_PENDING ||
          state==AB_OPERATION_UNKNOWN))
         ledger.SetState(lineage.pending_operation_id,AB_OPERATION_REJECTED);
      if(registry.RejectSLPending(lineage.pending_operation_id))
        {
         AB_ClearTradeOperationCorrelation(lineage.pending_operation_id);
         AB_ClearUnmatchedDealsForOperation(lineage.pending_operation_id);
         resolved++;
         Print("AB_DIAG auto-sl stale pending cleared for retry ticket=",
               lineage.current_ticket," entity=",lineage.entity_id.value,
               " operation=",lineage.pending_operation_id,
               " record_found=",record_found,
               " state=",(int)state,
               " age_seconds=",created_at>0 ? now-created_at : -1);
        }
     }
   return resolved;
  }

int AB_CaptureNormalAutoSLTriggers(AB_PositionRegistry &registry,
                                   AB_AutoSLTriggerLatchBook &latches,
                                   const AB_SymbolRules &rules,
                                   const MqlTick &ticks[],
                                   const int trigger_micro_points)
  {
   if(trigger_micro_points<=0 || ArraySize(ticks)<=0)
      return 0;
   int captured=0;
   latches.Prune(registry);
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed || lineage.auto_sl_done ||
         lineage.auto_sl_pending || lineage.sl_mode!=AB_SL_NONE)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)!=lineage.position_identifier)
         continue;
      double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE position_type=
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double best_profit_micro_points=0.0;
      if(!AB_AutoSLTriggerReachedInTicks(position_type,open_price,rules,
                                         trigger_micro_points,ticks,
                                         best_profit_micro_points))
         continue;
      double previous_best=0.0;
      ulong previous_time=0;
      bool already_latched=latches.IsTriggered(lineage.entity_id,previous_best,previous_time);
      ulong trigger_time_msc=(ulong)ticks[ArraySize(ticks)-1].time_msc;
      if(!latches.MarkTriggered(lineage.entity_id,best_profit_micro_points,
                                trigger_time_msc))
         continue;
      if(!already_latched)
        {
         captured++;
         Print("AB_DIAG auto-sl trigger latched ticket=",lineage.current_ticket,
               " entity=",lineage.entity_id.value,
               " peak_micro_points=",DoubleToString(best_profit_micro_points,1),
               " threshold=",trigger_micro_points,
               " ticks_scanned=",ArraySize(ticks));
        }
     }
   return captured;
  }

int AB_ProcessNormalAutomaticSLReliable(AB_PositionRegistry &registry,
                                        AB_OperationLedger &ledger,
                                        AB_AutoSLTriggerLatchBook &latches,
                                        const AB_SymbolRules &rules,
                                        const MqlTick &current_tick,
                                        const AB_BasketSnapshot &long_basket,
                                        const AB_BasketSnapshot &short_basket,
                                        const bool use_m1,
                                        const int entry_offset_micro_points,
                                        const int m1_offset_micro_points)
  {
   AB_ReconcileNormalAutoSLPending(registry,ledger,latches);
   int submitted=0;
   for(int i=0;i<registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(lineage.auto_sl_done)
        {
         latches.Clear(lineage.entity_id);
         continue;
        }
      double peak_profit_micro_points=0.0;
      ulong trigger_time_msc=0;
      if(!latches.IsTriggered(lineage.entity_id,peak_profit_micro_points,trigger_time_msc) ||
         lineage.auto_sl_pending || lineage.sl_mode!=AB_SL_NONE)
         continue;
      if(AB_BasketSuspendsNormalSL(long_basket,lineage.position_identifier) ||
         AB_BasketSuspendsNormalSL(short_basket,lineage.position_identifier))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "basket_suspended","");
         continue;
        }
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)!=lineage.position_identifier)
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "ticket_unavailable","");
         continue;
        }
      AB_NormalPositionState position;
      position.entity_id=lineage.entity_id;
      position.position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      position.current_ticket=lineage.current_ticket;
      position.position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      position.symbol=PositionGetString(POSITION_SYMBOL);
      position.open_time=(datetime)PositionGetInteger(POSITION_TIME);
      position.open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      position.current_sl=PositionGetDouble(POSITION_SL);
      position.current_tp=PositionGetDouble(POSITION_TP);
      position.auto_sl_done=false;

      double target_sl=0.0;
      bool target_ok=use_m1
         ? AB_ComputeM1SL(position,rules,m1_offset_micro_points,target_sl)
         : true;
      if(!use_m1)
         target_sl=AB_ComputeEntrySL(position,rules,entry_offset_micro_points);
      if(!target_ok)
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "m1_target_unavailable","");
         continue;
        }
      if(!AB_IsSLTightening(position,target_sl))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "target_not_tightening",
                            "current_sl="+DoubleToString(position.current_sl,rules.digits)+
                            " target_sl="+DoubleToString(target_sl,rules.digits));
         continue;
        }
      if(!AB_IsSLTargetUsable(position,rules,current_tick,target_sl))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "target_not_usable_now",
                            "bid="+DoubleToString(current_tick.bid,rules.digits)+
                            " ask="+DoubleToString(current_tick.ask,rules.digits)+
                            " target_sl="+DoubleToString(target_sl,rules.digits));
         continue;
        }
      if(ledger.HasInFlightForEntity(lineage.entity_id))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "entity_operation_inflight",
                            "ledger_count="+IntegerToString(ledger.Count()));
         continue;
        }
      MqlTradeRequest request;
      if(!AB_PreparePositionSLTPRequest(position.symbol,position.current_ticket,target_sl,
                                         position.current_tp,request))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "request_prepare_failed","");
         continue;
        }
      ulong operation_id=0;
      AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
      if(!AB_SendTradeRequest(request,ledger,lineage.entity_id,0.0,
                              operation_id,result_kind))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "request_send_failed",
                            "ledger_count="+IntegerToString(ledger.Count()));
         continue;
        }
      if(!AB_ShouldKeepAutoSLPending(result_kind))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "request_immediate_reject",
                            "result_kind="+IntegerToString((int)result_kind)+
                            " operation="+IntegerToString((long)operation_id));
         continue;
        }
      if(!registry.MarkSLPending(lineage.entity_id,operation_id))
        {
         latches.LogBlocked(lineage.entity_id,lineage.current_ticket,
                            "pending_bind_failed",
                            "operation="+IntegerToString((long)operation_id));
         continue;
        }
      submitted++;
      Print("AB_DIAG auto-sl request submitted ticket=",lineage.current_ticket,
            " entity=",lineage.entity_id.value,
            " operation=",operation_id,
            " target_sl=",DoubleToString(target_sl,rules.digits),
            " peak_micro_points=",DoubleToString(peak_profit_micro_points,1),
            " trigger_time_msc=",trigger_time_msc);
     }
   return submitted;
  }

#endif
