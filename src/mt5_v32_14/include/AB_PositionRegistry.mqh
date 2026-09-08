#ifndef AB_POSITION_REGISTRY_MQH
#define AB_POSITION_REGISTRY_MQH

#include "AB_Types.mqh"

struct AB_PositionLineage
  {
   AB_ManagedEntityId entity_id;
   ulong position_identifier;
   ulong current_ticket;
   string symbol;
   bool managed;
   double original_volume;
   AB_SL_MODE sl_mode;
   bool auto_sl_done;
   bool auto_sl_pending;
   ulong pending_operation_id;
   int trailing_distance_micro_points;
  };

class AB_PositionRegistry
  {
private:
   AB_PositionLineage m_items[128];
   int m_count;

   int FindByEntity(const AB_ManagedEntityId &entity_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==entity_id.value)
            return i;
      return -1;
     }

   int FindByPositionIdentifier(const ulong position_identifier)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].position_identifier==position_identifier)
            return i;
      return -1;
     }

public:
   AB_PositionRegistry(void)
     {
      m_count=0;
     }

   bool Register(const AB_ManagedEntityId &entity_id,const ulong ticket)
     {
       if(m_count>=128 || ticket==0 || !PositionSelectByTicket(ticket))
          return false;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      int index=FindByEntity(entity_id);
      if(index<0)
         index=FindByPositionIdentifier(position_identifier);
       if(index<0)
          index=m_count++;
       m_items[index].entity_id=entity_id;
      m_items[index].position_identifier=position_identifier;
       m_items[index].current_ticket=(ulong)PositionGetInteger(POSITION_TICKET);
       m_items[index].symbol=PositionGetString(POSITION_SYMBOL);
       m_items[index].managed=true;
      m_items[index].original_volume=PositionGetDouble(POSITION_VOLUME);
      m_items[index].sl_mode=AB_SL_NONE;
      m_items[index].auto_sl_done=false;
      m_items[index].auto_sl_pending=false;
      m_items[index].pending_operation_id=0;
      m_items[index].trailing_distance_micro_points=0;
      return true;
     }

   bool IsRegistered(const ulong position_identifier)
     {
       return position_identifier!=0 && FindByPositionIdentifier(position_identifier)>=0;
     }

   int ManagedCount(void) const
     {
      int count=0;
      for(int i=0;i<m_count;i++)
         if(m_items[i].managed)
            count++;
      return count;
     }

   int Count(void) const
     {
      return m_count;
     }

   bool GetAt(const int index,AB_PositionLineage &lineage)
     {
       if(index<0 || index>=m_count)
          return false;
       lineage=m_items[index];
       return true;
     }

   bool GetByPositionIdentifier(const ulong position_identifier,
                                AB_PositionLineage &lineage)
     {
      int index=FindByPositionIdentifier(position_identifier);
      if(index<0)
         return false;
      lineage=m_items[index];
      return true;
     }

   bool GetByTicket(const ulong ticket,AB_PositionLineage &lineage)
     {
      if(ticket==0)
         return false;
      for(int i=0;i<m_count;i++)
         if(m_items[i].current_ticket==ticket)
           {
            lineage=m_items[i];
            return true;
           }
      if(!PositionSelectByTicket(ticket))
         return false;
      return GetByPositionIdentifier((ulong)PositionGetInteger(POSITION_IDENTIFIER),lineage);
     }

   bool SetManaged(const AB_ManagedEntityId &entity_id,const bool managed)
     {
      int index=FindByEntity(entity_id);
      if(index<0)
         return false;
      m_items[index].managed=managed;
      return true;
     }

   bool SetManagedByPositionIdentifier(const ulong position_identifier,
                                       const bool managed)
     {
      int index=FindByPositionIdentifier(position_identifier);
      if(index<0)
         return false;
      m_items[index].managed=managed;
      return true;
     }

   bool MarkSLPending(const AB_ManagedEntityId &entity_id,const ulong operation_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0)
         return false;
      m_items[index].auto_sl_pending=true;
      m_items[index].pending_operation_id=operation_id;
      return true;
     }

   bool MarkSLCompleted(const AB_ManagedEntityId &entity_id,
                        const ulong operation_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0 || operation_id==0 || !m_items[index].auto_sl_pending ||
         m_items[index].pending_operation_id!=operation_id)
         return false;
      m_items[index].auto_sl_pending=false;
      m_items[index].pending_operation_id=0;
      if(m_items[index].sl_mode==AB_SL_NONE)
         m_items[index].auto_sl_done=true;
      return true;
     }

   bool RejectSLPending(const ulong operation_id)
     {
      if(operation_id==0)
         return false;
      for(int i=0;i<m_count;i++)
         if(m_items[i].auto_sl_pending &&
            m_items[i].pending_operation_id==operation_id)
           {
            m_items[i].auto_sl_pending=false;
            m_items[i].pending_operation_id=0;
            return true;
           }
      return false;
     }

   bool RearmAutomaticSL(const AB_ManagedEntityId &entity_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0 || m_items[index].auto_sl_pending ||
         m_items[index].sl_mode!=AB_SL_NONE || !m_items[index].auto_sl_done)
         return false;
      m_items[index].auto_sl_done=false;
      return true;
     }

   bool SetSLMode(const AB_ManagedEntityId &entity_id,
                  const AB_SL_MODE mode,
                  const int trailing_distance_micro_points)
     {
      int index=FindByEntity(entity_id);
      if(index<0 || m_items[index].auto_sl_pending)
         return false;
      m_items[index].sl_mode=mode;
      m_items[index].trailing_distance_micro_points=
         mode>=AB_SL_TRAILING_1 && mode<=AB_SL_TRAILING_4
         ? trailing_distance_micro_points : 0;
      return true;
     }

   bool StopTrailing(const AB_ManagedEntityId &entity_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0 || m_items[index].auto_sl_pending)
         return false;
      m_items[index].sl_mode=AB_SL_STOPPED;
      m_items[index].trailing_distance_micro_points=0;
      return true;
     }

   bool RefreshTicket(const AB_ManagedEntityId &entity_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0 || m_items[index].position_identifier==0)
         return false;
      int total=PositionsTotal();
      for(int i=0;i<total;i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket))
            continue;
         if((ulong)PositionGetInteger(POSITION_IDENTIFIER)==m_items[index].position_identifier)
           {
            m_items[index].current_ticket=ticket;
            return true;
           }
        }
      return false;
     }

   bool Get(const AB_ManagedEntityId &entity_id,AB_PositionLineage &lineage)
     {
      int index=FindByEntity(entity_id);
      if(index<0)
         return false;
      lineage=m_items[index];
      return true;
    }

   bool Restore(const AB_PositionLineage &lineage)
     {
      if(lineage.entity_id.value==0 || lineage.position_identifier==0 ||
         m_count>=128)
         return false;
      int index=FindByEntity(lineage.entity_id);
      if(index<0)
         index=m_count++;
      m_items[index]=lineage;
      return true;
     }

   bool RemoveByEntity(const AB_ManagedEntityId &entity_id)
     {
      int index=FindByEntity(entity_id);
      if(index<0)
         return false;
      for(int i=index;i<m_count-1;i++)
         m_items[i]=m_items[i+1];
      m_count--;
      return true;
     }

   bool HasUniqueHistoryEvidence(const ulong position_identifier)
     {
      if(position_identifier==0 || !HistorySelect(0,TimeCurrent()))
         return false;
      int matches=0;
      int total=HistoryDealsTotal();
      for(int i=0;i<total;i++)
        {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0)
            continue;
         if((ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID)==position_identifier)
            matches++;
        }
      return matches==1;
     }
  };

#endif
