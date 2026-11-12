#ifndef AB_STRADDLE_ENGINE_MQH
#define AB_STRADDLE_ENGINE_MQH

#include "AB_Types.mqh"
#include "AB_SymbolRules.mqh"

enum AB_STRADDLE_PHASE
  {
   AB_STRADDLE_NONE = 0,
   AB_STRADDLE_PLACING,
   AB_STRADDLE_ACTIVE,
   AB_STRADDLE_ROLLING_BACK,
   AB_STRADDLE_SETTLING,
   AB_STRADDLE_DONE
  };

struct AB_StraddlePrices
  {
   double buy_stop_price;
   double sell_stop_price;
  };

struct AB_StraddleState
  {
   AB_ManagedEntityId entity_id;
   AB_STRADDLE_PHASE phase;
   ulong buy_order_ticket;
   ulong sell_order_ticket;
   ulong filled_position_identifier;
   bool buy_placed;
   bool sell_placed;
   bool opposite_cancel_pending;
   bool rollback_pending;
   double actual_fill_price;
   ulong buy_pending_operation_id;
   ulong sell_pending_operation_id;
   ulong rollback_operation_id;
  };

void AB_RecordStraddlePlacementAccepted(AB_StraddleState &state,
                                        const bool buy_side,
                                        const ulong operation_id)
  {
   state.phase=AB_STRADDLE_PLACING;
   if(buy_side)
     {
      state.buy_placed=true;
      state.buy_pending_operation_id=operation_id;
     }
   else
     {
      state.sell_placed=true;
      state.sell_pending_operation_id=operation_id;
     }
  }

void AB_RecordStraddleOrderTicket(AB_StraddleState &state,
                                  const bool buy_side,
                                  const ulong order_ticket)
  {
   if(buy_side)
      state.buy_order_ticket=order_ticket;
   else
      state.sell_order_ticket=order_ticket;
  }

struct AB_BreakoutLineage
  {
   AB_ManagedEntityId entity_id;
   ulong position_identifier;
   ulong current_ticket;
   string symbol;
   ENUM_POSITION_TYPE position_type;
   double original_volume;
   bool managed;
   bool initial_sl_done;
   bool auto_sl_done;
   bool sl_pending;
   ulong pending_operation_id;
   int pending_kind;
  };

class AB_BreakoutRegistry
  {
private:
   AB_BreakoutLineage m_items[128];
   int m_count;

public:
   AB_BreakoutRegistry(void) { m_count=0; }

   int Count(void) const { return m_count; }

   int ManagedCount(void) const
     {
      int count=0;
      for(int i=0;i<m_count;i++)
         if(m_items[i].managed)
            count++;
      return count;
     }

   bool IsRegistered(const ulong position_identifier)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].position_identifier==position_identifier)
            return true;
      return false;
     }

   bool Register(const AB_ManagedEntityId &entity_id,const ulong ticket)
     {
      if(m_count>=128 || ticket==0 || !PositionSelectByTicket(ticket))
         return false;
      AB_BreakoutLineage item;
      ZeroMemory(item);
      item.entity_id=entity_id;
      item.position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      item.current_ticket=(ulong)PositionGetInteger(POSITION_TICKET);
      item.symbol=PositionGetString(POSITION_SYMBOL);
      item.position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      item.original_volume=PositionGetDouble(POSITION_VOLUME);
      item.managed=true;
      item.initial_sl_done=false;
      item.auto_sl_done=false;
      item.sl_pending=false;
      item.pending_operation_id=0;
      item.pending_kind=0;
      m_items[m_count++]=item;
      return true;
     }

   bool GetAt(const int index,AB_BreakoutLineage &item)
     {
      if(index<0 || index>=m_count)
         return false;
      item=m_items[index];
      return true;
     }

   bool GetByTicket(const ulong ticket,AB_BreakoutLineage &item)
     {
      if(ticket==0)
         return false;
      for(int i=0;i<m_count;i++)
         if(m_items[i].current_ticket==ticket)
           {
            item=m_items[i];
            return true;
           }
      if(!PositionSelectByTicket(ticket))
         return false;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      for(int i=0;i<m_count;i++)
         if(m_items[i].position_identifier==position_identifier)
           {
            item=m_items[i];
            return true;
           }
      return false;
     }

   bool Restore(const AB_BreakoutLineage &item)
     {
      if(item.entity_id.value==0 || item.position_identifier==0 || m_count>=128)
         return false;
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==item.entity_id.value)
           {
            m_items[i]=item;
            return true;
           }
      m_items[m_count++]=item;
      return true;
     }

   bool RemoveByEntity(const AB_ManagedEntityId &entity_id)
     {
      for(int index=0;index<m_count;index++)
         if(m_items[index].entity_id.value==entity_id.value)
           {
            for(int i=index;i<m_count-1;i++)
               m_items[i]=m_items[i+1];
            m_count--;
            return true;
           }
      return false;
     }

   bool MarkPending(const AB_ManagedEntityId &entity_id,const ulong operation_id,const int kind)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==entity_id.value)
           {
            m_items[i].sl_pending=true;
            m_items[i].pending_operation_id=operation_id;
            m_items[i].pending_kind=kind;
            return true;
           }
      return false;
     }

   bool ConfirmExistingInitialSL(const AB_ManagedEntityId &entity_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==entity_id.value && !m_items[i].sl_pending)
           {
            m_items[i].initial_sl_done=true;
            return true;
           }
      return false;
     }

   bool MarkSLCompleted(const ulong operation_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].pending_operation_id==operation_id)
           {
            if(m_items[i].pending_kind==1)
               m_items[i].initial_sl_done=true;
            else if(m_items[i].pending_kind==2)
               m_items[i].auto_sl_done=true;
            m_items[i].sl_pending=false;
            m_items[i].pending_operation_id=0;
            m_items[i].pending_kind=0;
            return true;
           }
      return false;
     }

   bool RejectSLPending(const ulong operation_id)
     {
      if(operation_id==0)
         return false;
      for(int i=0;i<m_count;i++)
         if(m_items[i].sl_pending &&
            m_items[i].pending_operation_id==operation_id)
           {
            m_items[i].sl_pending=false;
            m_items[i].pending_operation_id=0;
            m_items[i].pending_kind=0;
            return true;
           }
      return false;
     }
  };

bool AB_ComputeStraddlePrices(const AB_SymbolRules &rules,
                              const MqlTick &tick,
                              const int distance_micro_points,
                              AB_StraddlePrices &prices)
  {
   if(distance_micro_points<=0 || rules.point<=0.0 || tick.bid<=0.0 || tick.ask<=0.0)
      return false;
   double distance=AB_MicroPointDistance(rules,distance_micro_points);
   prices.buy_stop_price=tick.ask+distance;
   prices.sell_stop_price=tick.bid-distance;
   return prices.buy_stop_price>0.0 && prices.sell_stop_price>0.0;
  }

void AB_RecordStraddleFill(AB_StraddleState &state,
                           const ulong position_identifier,
                           const double actual_fill_price)
  {
   state.filled_position_identifier=position_identifier;
   state.actual_fill_price=actual_fill_price;
   state.phase=AB_STRADDLE_ACTIVE;
   state.opposite_cancel_pending=true;
  }

void AB_RecordOppositeCancelComplete(AB_StraddleState &state)
  {
   state.opposite_cancel_pending=false;
   state.phase=AB_STRADDLE_ACTIVE;
  }

void AB_RequestStraddleSettlement(AB_StraddleState &state)
  {
   state.phase=AB_STRADDLE_SETTLING;
  }

#endif
