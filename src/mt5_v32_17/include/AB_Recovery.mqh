#ifndef AB_RECOVERY_MQH
#define AB_RECOVERY_MQH

#include "AB_PositionRegistry.mqh"
#include "AB_StraddleEngine.mqh"
#include "AB_OperationLedger.mqh"

bool AB_HistoryContainsPosition(const ulong position_identifier)
  {
   if(position_identifier==0 || !HistorySelect(0,TimeCurrent()))
      return false;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal!=0 && (ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID)==position_identifier)
         return true;
     }
   return false;
  }

bool AB_VerifyPositionLineage(const AB_PositionLineage &lineage)
  {
   if(lineage.position_identifier==0)
      return false;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket) &&
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)==lineage.position_identifier)
         return true;
     }
   return AB_HistoryContainsPosition(lineage.position_identifier);
  }

bool AB_VerifyBreakoutLineage(const AB_BreakoutLineage &lineage)
  {
   if(lineage.position_identifier==0)
      return false;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket) &&
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)==lineage.position_identifier)
         return true;
     }
   return AB_HistoryContainsPosition(lineage.position_identifier);
  }

bool AB_VerifyOperationRecord(const AB_OperationRecord &record)
  {
   if(record.operation_id==0)
      return false;
   if(record.request_id==0)
      return record.state==AB_OPERATION_ACCEPTED ||
             record.state==AB_OPERATION_REJECTED ||
             record.state==AB_OPERATION_TEMPORARY ||
             record.state==AB_OPERATION_COMPLETED;
   if(!HistorySelect(0,TimeCurrent()))
      return false;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal!=0 && (ulong)HistoryDealGetInteger(deal,DEAL_ORDER)==record.request_id)
         return true;
     }
   return record.state!=AB_OPERATION_UNKNOWN;
  }

#endif
