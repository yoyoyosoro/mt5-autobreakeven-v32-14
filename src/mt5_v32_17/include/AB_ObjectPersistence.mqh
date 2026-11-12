#ifndef AB_OBJECT_PERSISTENCE_MQH
#define AB_OBJECT_PERSISTENCE_MQH

#include "AB_PositionRegistry.mqh"
#include "AB_StraddleEngine.mqh"
#include "AB_LadderEngine.mqh"
#include "AB_BasketEngine.mqh"
#include "AB_OperationLedger.mqh"

string AB_ObjectFileA(void) { return AB_LedgerNamespace()+"_objects_A.bin"; }
string AB_ObjectFileB(void) { return AB_LedgerNamespace()+"_objects_B.bin"; }

void AB_WritePersistedString(const int handle,const string value)
  {
   int length=StringLen(value);
   FileWriteInteger(handle,length,INT_VALUE);
   if(length>0)
      FileWriteString(handle,value,length);
  }

bool AB_ReadPersistedString(const int handle,string &value)
  {
   int length=FileReadInteger(handle,INT_VALUE);
   if(length<0 || length>128)
      return false;
   value=length>0 ? FileReadString(handle,length) : "";
   return true;
  }

ulong AB_ObjectChecksum(const ulong sequence,const int normal_count,
                        const int breakout_count,const int normal_ladder_count,
                        const int breakout_ladder_count,const int ledger_count,
                        const AB_BasketSnapshot &basket_long,
                        const AB_BasketSnapshot &basket_short,
                        const AB_StraddleState &straddle)
  {
   ulong value=1469598103934665603;
   value=(value^sequence)*1099511628211;
   value=(value^(ulong)normal_count)*1099511628211;
   value=(value^(ulong)breakout_count)*1099511628211;
   value=(value^(ulong)normal_ladder_count)*1099511628211;
   value=(value^(ulong)breakout_ladder_count)*1099511628211;
   value=(value^(ulong)ledger_count)*1099511628211;
   value=(value^basket_long.basket_id.value)*1099511628211;
   value=(value^(ulong)basket_long.member_count)*1099511628211;
   value=(value^(basket_long.no_ladder?1:0))*1099511628211;
   value=(value^basket_short.basket_id.value)*1099511628211;
   value=(value^(ulong)basket_short.member_count)*1099511628211;
   value=(value^(basket_short.no_ladder?1:0))*1099511628211;
   value=(value^straddle.entity_id.value)*1099511628211;
   value=(value^straddle.buy_order_ticket)*1099511628211;
   value=(value^straddle.sell_order_ticket)*1099511628211;
   return value;
  }

bool AB_WriteBasketSnapshot(const int handle,const AB_BasketSnapshot &basket)
  {
   AB_WriteUlong(handle,basket.basket_id.value);
   FileWriteInteger(handle,(int)basket.phase,INT_VALUE);
   FileWriteInteger(handle,(int)basket.exit_mode,INT_VALUE);
   FileWriteInteger(handle,(int)basket.direction,INT_VALUE);
   AB_WritePersistedString(handle,basket.symbol);
   FileWriteInteger(handle,basket.member_count,INT_VALUE);
   for(int i=0;i<basket.member_count;i++)
     {
      AB_WriteUlong(handle,basket.members[i].entity_id.value);
      AB_WriteUlong(handle,basket.members[i].position_identifier);
      FileWriteDouble(handle,basket.members[i].volume);
      FileWriteDouble(handle,basket.members[i].open_price);
      FileWriteDouble(handle,basket.members[i].frozen_net_result);
      FileWriteInteger(handle,basket.members[i].active?1:0,INT_VALUE);
      FileWriteInteger(handle,basket.members[i].combo_sl_suppressed?1:0,INT_VALUE);
      FileWriteInteger(handle,basket.members[i].tp_installed?1:0,INT_VALUE);
      FileWriteDouble(handle,basket.members[i].owned_tp);
      FileWriteInteger(handle,basket.members[i].one_shot_sl_installed?1:0,INT_VALUE);
      AB_WriteUlong(handle,basket.members[i].pending_operation_id);
      FileWriteInteger(handle,basket.members[i].pending_kind,INT_VALUE);
     }
   FileWriteInteger(handle,basket.ladder_event_count,INT_VALUE);
   for(int i=0;i<basket.ladder_event_count;i++)
     {
      FileWriteDouble(handle,basket.ladder_events[i].price);
      FileWriteDouble(handle,basket.ladder_events[i].close_volume);
     }
   FileWriteDouble(handle,basket.zero_price);
   FileWriteDouble(handle,basket.frozen_bid);
   FileWriteDouble(handle,basket.frozen_ask);
   FileWriteDouble(handle,basket.frozen_spread);
   FileWriteDouble(handle,basket.frozen_point);
   FileWriteDouble(handle,basket.frozen_tick_size);
   FileWriteDouble(handle,basket.frozen_tick_value);
   FileWriteDouble(handle,basket.frozen_net_result);
   FileWriteDouble(handle,basket.favorable_extreme);
   FileWriteInteger(handle,basket.trailing_paused?1:0,INT_VALUE);
   FileWriteInteger(handle,basket.force_close?1:0,INT_VALUE);
   FileWriteInteger(handle,basket.no_ladder?1:0,INT_VALUE);
   return true;
  }

bool AB_ReadBasketSnapshot(const int handle,AB_BasketSnapshot &basket)
  {
   basket.basket_id.value=AB_ReadUlong(handle);
   basket.phase=(AB_BASKET_PHASE)FileReadInteger(handle,INT_VALUE);
   basket.exit_mode=(AB_BASKET_EXIT_MODE)FileReadInteger(handle,INT_VALUE);
   basket.direction=(ENUM_POSITION_TYPE)FileReadInteger(handle,INT_VALUE);
   if(!AB_ReadPersistedString(handle,basket.symbol))
      return false;
   basket.member_count=FileReadInteger(handle,INT_VALUE);
   if(basket.member_count<0 || basket.member_count>64)
      return false;
   for(int i=0;i<basket.member_count;i++)
     {
      basket.members[i].entity_id.value=AB_ReadUlong(handle);
      basket.members[i].position_identifier=AB_ReadUlong(handle);
      basket.members[i].volume=FileReadDouble(handle);
      basket.members[i].open_price=FileReadDouble(handle);
      basket.members[i].frozen_net_result=FileReadDouble(handle);
      basket.members[i].active=FileReadInteger(handle,INT_VALUE)!=0;
      basket.members[i].combo_sl_suppressed=FileReadInteger(handle,INT_VALUE)!=0;
      basket.members[i].tp_installed=FileReadInteger(handle,INT_VALUE)!=0;
      basket.members[i].owned_tp=FileReadDouble(handle);
      basket.members[i].one_shot_sl_installed=FileReadInteger(handle,INT_VALUE)!=0;
      basket.members[i].pending_operation_id=AB_ReadUlong(handle);
      basket.members[i].pending_kind=FileReadInteger(handle,INT_VALUE);
     }
   basket.ladder_event_count=FileReadInteger(handle,INT_VALUE);
   if(basket.ladder_event_count<0 || basket.ladder_event_count>640)
      return false;
   for(int i=0;i<basket.ladder_event_count;i++)
     {
      basket.ladder_events[i].price=FileReadDouble(handle);
      basket.ladder_events[i].close_volume=FileReadDouble(handle);
     }
   basket.zero_price=FileReadDouble(handle);
   basket.frozen_bid=FileReadDouble(handle);
   basket.frozen_ask=FileReadDouble(handle);
   basket.frozen_spread=FileReadDouble(handle);
   basket.frozen_point=FileReadDouble(handle);
   basket.frozen_tick_size=FileReadDouble(handle);
   basket.frozen_tick_value=FileReadDouble(handle);
   basket.frozen_net_result=FileReadDouble(handle);
   basket.favorable_extreme=FileReadDouble(handle);
   basket.trailing_paused=FileReadInteger(handle,INT_VALUE)!=0;
   basket.force_close=FileReadInteger(handle,INT_VALUE)!=0;
   basket.no_ladder=FileReadInteger(handle,INT_VALUE)!=0;
   return true;
  }

bool AB_WriteObjectSnapshot(const int slot,const ulong sequence,
                            AB_PositionRegistry &normal,
                            AB_BreakoutRegistry &breakout,
                            AB_LadderBook &normal_ladder,
                            AB_LadderBook &breakout_ladder,
                            AB_OperationLedger &ledger,
                            const AB_BasketSnapshot &basket_long,
                            const AB_BasketSnapshot &basket_short,
                            const AB_StraddleState &straddle)
  {
   string file_name=slot==0 ? AB_ObjectFileA() : AB_ObjectFileB();
   int handle=FileOpen(file_name,FILE_BIN|FILE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;
   AB_WriteUlong(handle,sequence);
   FileWriteInteger(handle,normal.Count(),INT_VALUE);
   for(int i=0;i<normal.Count();i++)
     {
      AB_PositionLineage item;
      if(!normal.GetAt(i,item)) { FileClose(handle); return false; }
      AB_WriteUlong(handle,item.entity_id.value);
      AB_WriteUlong(handle,item.position_identifier);
      AB_WriteUlong(handle,item.current_ticket);
      AB_WritePersistedString(handle,item.symbol);
      FileWriteInteger(handle,item.managed?1:0,INT_VALUE);
      FileWriteDouble(handle,item.original_volume);
      FileWriteInteger(handle,(int)item.sl_mode,INT_VALUE);
      FileWriteInteger(handle,item.auto_sl_done?1:0,INT_VALUE);
      FileWriteInteger(handle,item.auto_sl_pending?1:0,INT_VALUE);
      AB_WriteUlong(handle,item.pending_operation_id);
      FileWriteInteger(handle,item.trailing_distance_micro_points,INT_VALUE);
     }
   FileWriteInteger(handle,breakout.Count(),INT_VALUE);
   for(int i=0;i<breakout.Count();i++)
     {
      AB_BreakoutLineage item;
      if(!breakout.GetAt(i,item)) { FileClose(handle); return false; }
      AB_WriteUlong(handle,item.entity_id.value);
      AB_WriteUlong(handle,item.position_identifier);
      AB_WriteUlong(handle,item.current_ticket);
      AB_WritePersistedString(handle,item.symbol);
      FileWriteInteger(handle,(int)item.position_type,INT_VALUE);
      FileWriteDouble(handle,item.original_volume);
      FileWriteInteger(handle,item.managed?1:0,INT_VALUE);
      FileWriteInteger(handle,item.initial_sl_done?1:0,INT_VALUE);
      FileWriteInteger(handle,item.auto_sl_done?1:0,INT_VALUE);
      FileWriteInteger(handle,item.sl_pending?1:0,INT_VALUE);
      AB_WriteUlong(handle,item.pending_operation_id);
      FileWriteInteger(handle,item.pending_kind,INT_VALUE);
     }
   FileWriteInteger(handle,normal_ladder.Count(),INT_VALUE);
   for(int i=0;i<normal_ladder.Count();i++)
     {
      AB_LadderPositionState item;
      if(!normal_ladder.GetAt(i,item)) { FileClose(handle); return false; }
      AB_WriteUlong(handle,item.entity_id.value);
      FileWriteDouble(handle,item.original_volume);
      FileWriteDouble(handle,item.current_volume);
      FileWriteDouble(handle,item.profit_micro_points);
      for(int level=0;level<10;level++)
        {
         FileWriteInteger(handle,item.levels[level].enabled?1:0,INT_VALUE);
         FileWriteInteger(handle,item.levels[level].completed?1:0,INT_VALUE);
         FileWriteInteger(handle,item.levels[level].pending_request?1:0,INT_VALUE);
         AB_WriteUlong(handle,item.levels[level].pending_operation_id);
         FileWriteDouble(handle,item.levels[level].distance_micro_points);
         FileWriteDouble(handle,item.levels[level].ratio_percent);
         FileWriteDouble(handle,item.levels[level].planned_volume);
        }
     }
   FileWriteInteger(handle,breakout_ladder.Count(),INT_VALUE);
   for(int i=0;i<breakout_ladder.Count();i++)
     {
      AB_LadderPositionState item;
      if(!breakout_ladder.GetAt(i,item)) { FileClose(handle); return false; }
      AB_WriteUlong(handle,item.entity_id.value);
      FileWriteDouble(handle,item.original_volume);
      FileWriteDouble(handle,item.current_volume);
      FileWriteDouble(handle,item.profit_micro_points);
      for(int level=0;level<10;level++)
        {
         FileWriteInteger(handle,item.levels[level].enabled?1:0,INT_VALUE);
         FileWriteInteger(handle,item.levels[level].completed?1:0,INT_VALUE);
         FileWriteInteger(handle,item.levels[level].pending_request?1:0,INT_VALUE);
         AB_WriteUlong(handle,item.levels[level].pending_operation_id);
         FileWriteDouble(handle,item.levels[level].distance_micro_points);
         FileWriteDouble(handle,item.levels[level].ratio_percent);
         FileWriteDouble(handle,item.levels[level].planned_volume);
        }
     }
   FileWriteInteger(handle,ledger.Count(),INT_VALUE);
   for(int i=0;i<ledger.Count();i++)
     {
      AB_OperationRecord item;
      if(!ledger.GetAt(i,item)) { FileClose(handle); return false; }
      AB_WriteUlong(handle,item.operation_id);
      AB_WriteUlong(handle,item.request_id);
      AB_WriteUlong(handle,item.order_ticket);
      AB_WriteUlong(handle,item.entity_id.value);
      FileWriteInteger(handle,(int)item.state,INT_VALUE);
      FileWriteInteger(handle,(int)item.purpose,INT_VALUE);
      FileWriteInteger(handle,item.deal_required?1:0,INT_VALUE);
      FileWriteDouble(handle,item.requested_volume);
      FileWriteDouble(handle,item.completed_volume);
      AB_WriteUlong(handle,(ulong)item.created_at);
     }
   AB_WriteBasketSnapshot(handle,basket_long);
   AB_WriteBasketSnapshot(handle,basket_short);
   AB_WriteUlong(handle,straddle.entity_id.value);
   FileWriteInteger(handle,(int)straddle.phase,INT_VALUE);
   AB_WriteUlong(handle,straddle.buy_order_ticket);
   AB_WriteUlong(handle,straddle.sell_order_ticket);
   AB_WriteUlong(handle,straddle.filled_position_identifier);
   FileWriteInteger(handle,straddle.buy_placed?1:0,INT_VALUE);
   FileWriteInteger(handle,straddle.sell_placed?1:0,INT_VALUE);
   FileWriteInteger(handle,straddle.opposite_cancel_pending?1:0,INT_VALUE);
   FileWriteInteger(handle,straddle.rollback_pending?1:0,INT_VALUE);
   FileWriteDouble(handle,straddle.actual_fill_price);
   AB_WriteUlong(handle,straddle.buy_pending_operation_id);
   AB_WriteUlong(handle,straddle.sell_pending_operation_id);
   AB_WriteUlong(handle,straddle.rollback_operation_id);
      AB_WriteUlong(handle,AB_ObjectChecksum(sequence,normal.Count(),breakout.Count(),
      normal_ladder.Count(),breakout_ladder.Count(),ledger.Count(),
      basket_long,basket_short,straddle));
   FileFlush(handle);
   FileClose(handle);
   return true;
  }

bool AB_ReadLadderState(const int handle,AB_LadderPositionState &item)
  {
   item.entity_id.value=AB_ReadUlong(handle);
   item.original_volume=FileReadDouble(handle);
   item.current_volume=FileReadDouble(handle);
   item.profit_micro_points=FileReadDouble(handle);
   for(int level=0;level<10;level++)
     {
      item.levels[level].enabled=FileReadInteger(handle,INT_VALUE)!=0;
      item.levels[level].completed=FileReadInteger(handle,INT_VALUE)!=0;
      item.levels[level].pending_request=FileReadInteger(handle,INT_VALUE)!=0;
      item.levels[level].pending_operation_id=AB_ReadUlong(handle);
      item.levels[level].distance_micro_points=FileReadDouble(handle);
      item.levels[level].ratio_percent=FileReadDouble(handle);
      item.levels[level].planned_volume=FileReadDouble(handle);
     }
   return item.entity_id.value!=0;
  }

bool AB_ReadObjectSnapshot(const int slot,const ulong expected_sequence,
                           AB_PositionRegistry &normal,
                           AB_BreakoutRegistry &breakout,
                           AB_LadderBook &normal_ladder,
                           AB_LadderBook &breakout_ladder,
                           AB_OperationLedger &ledger,
                           AB_BasketSnapshot &basket_long,
                           AB_BasketSnapshot &basket_short,
                           AB_StraddleState &straddle)
  {
   string file_name=slot==0 ? AB_ObjectFileA() : AB_ObjectFileB();
   int handle=FileOpen(file_name,FILE_BIN|FILE_READ);
   if(handle==INVALID_HANDLE)
      return false;
   ulong sequence=AB_ReadUlong(handle);
   if(sequence!=expected_sequence) { FileClose(handle); return false; }
   int normal_count=FileReadInteger(handle,INT_VALUE);
   if(normal_count<0 || normal_count>128) { FileClose(handle); return false; }
   for(int i=0;i<normal_count;i++)
     {
      AB_PositionLineage item;
      item.entity_id.value=AB_ReadUlong(handle);
      item.position_identifier=AB_ReadUlong(handle);
      item.current_ticket=AB_ReadUlong(handle);
      if(!AB_ReadPersistedString(handle,item.symbol))
        { FileClose(handle); return false; }
      item.managed=FileReadInteger(handle,INT_VALUE)!=0;
      item.original_volume=FileReadDouble(handle);
      item.sl_mode=(AB_SL_MODE)FileReadInteger(handle,INT_VALUE);
      item.auto_sl_done=FileReadInteger(handle,INT_VALUE)!=0;
      item.auto_sl_pending=FileReadInteger(handle,INT_VALUE)!=0;
      item.pending_operation_id=AB_ReadUlong(handle);
      item.trailing_distance_micro_points=FileReadInteger(handle,INT_VALUE);
      if(!normal.Restore(item)) { FileClose(handle); return false; }
     }
   int breakout_count=FileReadInteger(handle,INT_VALUE);
   if(breakout_count<0 || breakout_count>128) { FileClose(handle); return false; }
   for(int i=0;i<breakout_count;i++)
     {
      AB_BreakoutLineage item;
      item.entity_id.value=AB_ReadUlong(handle);
      item.position_identifier=AB_ReadUlong(handle);
      item.current_ticket=AB_ReadUlong(handle);
      if(!AB_ReadPersistedString(handle,item.symbol))
        { FileClose(handle); return false; }
      item.position_type=(ENUM_POSITION_TYPE)FileReadInteger(handle,INT_VALUE);
      item.original_volume=FileReadDouble(handle);
      item.managed=FileReadInteger(handle,INT_VALUE)!=0;
      item.initial_sl_done=FileReadInteger(handle,INT_VALUE)!=0;
      item.auto_sl_done=FileReadInteger(handle,INT_VALUE)!=0;
      item.sl_pending=FileReadInteger(handle,INT_VALUE)!=0;
      item.pending_operation_id=AB_ReadUlong(handle);
      item.pending_kind=FileReadInteger(handle,INT_VALUE);
      if(!breakout.Restore(item)) { FileClose(handle); return false; }
     }
   int normal_ladder_count=FileReadInteger(handle,INT_VALUE);
   if(normal_ladder_count<0 || normal_ladder_count>128) { FileClose(handle); return false; }
   for(int i=0;i<normal_ladder_count;i++)
     {
      AB_LadderPositionState item;
      if(!AB_ReadLadderState(handle,item) || !normal_ladder.Restore(item))
        { FileClose(handle); return false; }
     }
   int breakout_ladder_count=FileReadInteger(handle,INT_VALUE);
   if(breakout_ladder_count<0 || breakout_ladder_count>128) { FileClose(handle); return false; }
   for(int i=0;i<breakout_ladder_count;i++)
     {
      AB_LadderPositionState item;
      if(!AB_ReadLadderState(handle,item) || !breakout_ladder.Restore(item))
        { FileClose(handle); return false; }
     }
   int ledger_count=FileReadInteger(handle,INT_VALUE);
   if(ledger_count<0 || ledger_count>AB_MAX_OPERATION_RECORDS) { FileClose(handle); return false; }
   for(int i=0;i<ledger_count;i++)
     {
      AB_OperationRecord item;
      item.operation_id=AB_ReadUlong(handle);
      item.request_id=AB_ReadUlong(handle);
      item.order_ticket=AB_ReadUlong(handle);
      item.entity_id.value=AB_ReadUlong(handle);
      item.state=(AB_OPERATION_STATE)FileReadInteger(handle,INT_VALUE);
      item.purpose=(AB_OPERATION_PURPOSE)FileReadInteger(handle,INT_VALUE);
      item.deal_required=FileReadInteger(handle,INT_VALUE)!=0;
      item.requested_volume=FileReadDouble(handle);
      item.completed_volume=FileReadDouble(handle);
      item.created_at=(datetime)AB_ReadUlong(handle);
      if(!ledger.Restore(item)) { FileClose(handle); return false; }
     }
   if(!AB_ReadBasketSnapshot(handle,basket_long) ||
      !AB_ReadBasketSnapshot(handle,basket_short))
     { FileClose(handle); return false; }
   straddle.entity_id.value=AB_ReadUlong(handle);
   straddle.phase=(AB_STRADDLE_PHASE)FileReadInteger(handle,INT_VALUE);
   straddle.buy_order_ticket=AB_ReadUlong(handle);
   straddle.sell_order_ticket=AB_ReadUlong(handle);
   straddle.filled_position_identifier=AB_ReadUlong(handle);
   straddle.buy_placed=FileReadInteger(handle,INT_VALUE)!=0;
   straddle.sell_placed=FileReadInteger(handle,INT_VALUE)!=0;
   straddle.opposite_cancel_pending=FileReadInteger(handle,INT_VALUE)!=0;
   straddle.rollback_pending=FileReadInteger(handle,INT_VALUE)!=0;
   straddle.actual_fill_price=FileReadDouble(handle);
   straddle.buy_pending_operation_id=AB_ReadUlong(handle);
   straddle.sell_pending_operation_id=AB_ReadUlong(handle);
   straddle.rollback_operation_id=AB_ReadUlong(handle);
   ulong checksum=AB_ReadUlong(handle);
   ulong expected_checksum=AB_ObjectChecksum(sequence,normal_count,breakout_count,
      normal_ladder_count,breakout_ladder_count,ledger_count,
      basket_long,basket_short,straddle);
   bool complete=FileTell(handle)==FileSize(handle);
   FileClose(handle);
   return complete && checksum==expected_checksum;
  }

#endif
