#ifndef AB_OPERATION_LEDGER_MQH
#define AB_OPERATION_LEDGER_MQH

#include "AB_Types.mqh"

#define AB_MAX_OPERATION_RECORDS 128

class AB_OperationLedger
  {
private:
   AB_OperationRecord m_records[AB_MAX_OPERATION_RECORDS];
   int m_count;
   ulong m_next_operation_id;

   int FindByOperation(const ulong operation_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_records[i].operation_id==operation_id)
            return i;
      return -1;
     }

   int FindByRequest(const ulong request_id)
     {
      if(request_id==0)
         return -1;
      for(int i=0;i<m_count;i++)
         if(m_records[i].request_id==request_id)
            return i;
      return -1;
     }

   int FindByOrder(const ulong order_ticket)
     {
      if(order_ticket==0)
         return -1;
      for(int i=0;i<m_count;i++)
         if(m_records[i].order_ticket==order_ticket)
            return i;
      return -1;
     }

   bool IsTerminal(const AB_OPERATION_STATE state) const
     {
      return state==AB_OPERATION_REJECTED ||
             state==AB_OPERATION_TEMPORARY;
     }

   bool CompactOneTerminalRecord(void)
     {
      if(m_count<AB_MAX_OPERATION_RECORDS)
         return true;
      int remove_index=-1;
      for(int i=0;i<m_count;i++)
         if(IsTerminal(m_records[i].state))
           {
            remove_index=i;
            break;
           }
      if(remove_index<0)
         return false;
      for(int i=remove_index;i<m_count-1;i++)
         m_records[i]=m_records[i+1];
      m_count--;
      return true;
     }

public:
   AB_OperationLedger(void)
     {
      m_count=0;
      m_next_operation_id=1;
     }

   int Count(void) const { return m_count; }

   bool GetAt(const int index,AB_OperationRecord &record) const
     {
      if(index<0 || index>=m_count)
         return false;
      record=m_records[index];
      return true;
     }

   bool FirstUnknownRequest(ulong &request_id) const
     {
      for(int i=0;i<m_count;i++)
         if(m_records[i].state==AB_OPERATION_UNKNOWN && m_records[i].request_id!=0)
           {
            request_id=m_records[i].request_id;
            return true;
           }
      request_id=0;
      return false;
     }

   int ResolveUnsubmittedUnknownOperations(void)
     {
      int resolved=0;
      for(int i=0;i<m_count;i++)
         if(m_records[i].state==AB_OPERATION_UNKNOWN &&
            m_records[i].request_id==0 && m_records[i].order_ticket==0)
           {
            m_records[i].state=AB_OPERATION_REJECTED;
            resolved++;
           }
      return resolved;
     }

   int ResolveStalePendingCloseOperations(const datetime before_time)
     {
      int resolved=0;
      for(int i=0;i<m_count;i++)
         if(m_records[i].deal_required &&
            m_records[i].purpose==AB_PURPOSE_CLOSE &&
            (m_records[i].state==AB_OPERATION_ACCEPTED ||
             m_records[i].state==AB_OPERATION_PENDING) &&
            m_records[i].order_ticket==0 &&
            m_records[i].completed_volume<=0.0 &&
            m_records[i].created_at<before_time)
           {
            m_records[i].state=AB_OPERATION_REJECTED;
            resolved++;
           }
      return resolved;
     }

   bool HasInFlightForEntity(const AB_ManagedEntityId &entity_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_records[i].entity_id.value==entity_id.value &&
            (m_records[i].state==AB_OPERATION_ACCEPTED ||
             m_records[i].state==AB_OPERATION_PENDING ||
             m_records[i].state==AB_OPERATION_UNKNOWN))
            return true;
      return false;
     }

   bool Begin(const AB_ManagedEntityId &entity_id,
              const double requested_volume,
              const AB_OPERATION_PURPOSE purpose,
              ulong &operation_id,
              const bool allow_parallel=false)
     {
      if(!allow_parallel && HasInFlightForEntity(entity_id))
         return false;
      if(m_count>=AB_MAX_OPERATION_RECORDS && !CompactOneTerminalRecord())
         return false;
      operation_id=m_next_operation_id++;
      if(m_next_operation_id==0)
         m_next_operation_id=1;
      int index=m_count++;
      m_records[index].operation_id=operation_id;
      m_records[index].request_id=0;
      m_records[index].order_ticket=0;
      m_records[index].entity_id=entity_id;
      m_records[index].state=AB_OPERATION_ACCEPTED;
      m_records[index].purpose=purpose;
      m_records[index].deal_required=(purpose==AB_PURPOSE_CLOSE);
      m_records[index].requested_volume=requested_volume;
      m_records[index].completed_volume=0.0;
      m_records[index].created_at=TimeCurrent();
      return true;
     }

   bool SetRequestId(const ulong operation_id,const ulong request_id)
     {
      int index=FindByOperation(operation_id);
      if(index<0)
         return false;
      m_records[index].request_id=request_id;
      m_records[index].state=AB_OPERATION_PENDING;
      return true;
     }

   bool SetOrderTicket(const ulong operation_id,const ulong order_ticket)
     {
      int index=FindByOperation(operation_id);
      if(index<0)
         return false;
      m_records[index].order_ticket=order_ticket;
      return true;
     }

   bool SetState(const ulong operation_id,const AB_OPERATION_STATE state)
     {
      int index=FindByOperation(operation_id);
      if(index<0)
         return false;
      m_records[index].state=state;
      return true;
     }

   bool RecordDeal(const ulong request_id,const double deal_volume)
     {
      int index=FindByRequest(request_id);
      if(index<0 || deal_volume<=0.0)
         return false;
      m_records[index].completed_volume+=deal_volume;
      if(m_records[index].completed_volume+1.0e-8>=m_records[index].requested_volume)
         m_records[index].state=AB_OPERATION_COMPLETED;
      else
         m_records[index].state=AB_OPERATION_PENDING;
      return true;
     }

   bool RecordDealByOrder(const ulong order_ticket,const double deal_volume)
     {
      if(order_ticket==0 || deal_volume<=0.0)
         return false;
      int index=FindByOrder(order_ticket);
      if(index<0)
         return false;
      m_records[index].completed_volume+=deal_volume;
      m_records[index].state=m_records[index].completed_volume+1.0e-8>=
         m_records[index].requested_volume ? AB_OPERATION_COMPLETED : AB_OPERATION_PENDING;
      return true;
     }

   bool RecordPositionUpdate(const ulong request_id)
     {
      int index=FindByRequest(request_id);
      if(index<0 || m_records[index].deal_required)
         return false;
      m_records[index].state=AB_OPERATION_COMPLETED;
      return true;
     }

   bool GetByRequest(const ulong request_id,AB_OperationRecord &record)
     {
      int index=FindByRequest(request_id);
      if(index<0)
         return false;
      record=m_records[index];
      return true;
     }

   bool GetByOrder(const ulong order_ticket,AB_OperationRecord &record)
     {
      int index=FindByOrder(order_ticket);
      if(index<0)
         return false;
      record=m_records[index];
      return true;
     }

   bool Get(const ulong operation_id,AB_OperationRecord &record)
     {
      int index=FindByOperation(operation_id);
      if(index<0)
         return false;
      record=m_records[index];
      return true;
    }

   bool RecordDealByOperation(const ulong operation_id,const double deal_volume)
     {
      int index=FindByOperation(operation_id);
      if(index<0 || !m_records[index].deal_required || deal_volume<=0.0)
         return false;
      m_records[index].completed_volume+=deal_volume;
      m_records[index].state=m_records[index].completed_volume+1.0e-8>=
         m_records[index].requested_volume ? AB_OPERATION_COMPLETED : AB_OPERATION_PENDING;
      return true;
     }

   bool Restore(const AB_OperationRecord &record)
     {
      if(record.operation_id==0 || m_count>=AB_MAX_OPERATION_RECORDS)
         return false;
      int index=FindByOperation(record.operation_id);
      if(index<0)
         index=m_count++;
      m_records[index]=record;
      if(record.operation_id>=m_next_operation_id)
         m_next_operation_id=record.operation_id+1;
      if(m_next_operation_id==0)
         m_next_operation_id=1;
      return true;
     }

   int RemoveByEntity(const AB_ManagedEntityId &entity_id)
     {
      int removed=0;
      for(int i=m_count-1;i>=0;i--)
         if(m_records[i].entity_id.value==entity_id.value)
           {
            for(int j=i;j<m_count-1;j++)
               m_records[j]=m_records[j+1];
            m_count--;
            removed++;
           }
      return removed;
     }
  };

#endif
