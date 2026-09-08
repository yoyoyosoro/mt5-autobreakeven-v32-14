#ifndef AB_BASKET_EXIT_V32_11_MQH
#define AB_BASKET_EXIT_V32_11_MQH

#include "AB_Runtime.mqh"

bool AB_BasketExitActivatedV32_11(const AB_BasketSnapshot &basket)
  {
   return basket.phase==AB_BASKET_EXITING ||
          basket.phase==AB_BASKET_FORCE_CLOSING;
  }

bool AB_TryActivateBasketExitV32_11(AB_BasketSnapshot &basket,
                                    const MqlTick &tick)
  {
   if(AB_BasketExitActivatedV32_11(basket))
      return true;
   if(basket.phase!=AB_BASKET_ACTIVE || !AB_BasketZeroReached(basket,tick))
      return false;
   basket.phase=AB_BASKET_EXITING;
   if(basket.exit_mode==AB_BASKET_EXIT_TRAILING)
      basket.favorable_extreme=basket.direction==POSITION_TYPE_BUY ? tick.bid : tick.ask;
   return true;
  }

bool AB_BasketOneShotReverseReachedV32_11(const AB_BasketSnapshot &basket,
                                          const MqlTick &tick,
                                          const int reverse_close_micro_points,
                                          const AB_SymbolRules &rules)
  {
   if(basket.exit_mode!=AB_BASKET_EXIT_ONE_SHOT_SL ||
      basket.phase!=AB_BASKET_EXITING || reverse_close_micro_points<=0)
      return false;
   double distance=AB_MicroPointDistance(rules,reverse_close_micro_points);
   return basket.direction==POSITION_TYPE_BUY
      ? tick.bid<=basket.zero_price-distance
      : tick.ask>=basket.zero_price+distance;
  }

int AB_ProcessBasketExitV32_11(AB_BasketSnapshot &basket,
                               AB_OperationLedger &ledger,
                               const AB_SymbolRules &rules,
                               const MqlTick &tick,
                               const int trailing_distance_micro_points,
                               const int reverse_close_micro_points,
                               const int slippage_micro_points)
  {
   if(basket.phase!=AB_BASKET_ACTIVE && basket.phase!=AB_BASKET_EXITING &&
      basket.phase!=AB_BASKET_FORCE_CLOSING)
      return 0;
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].active &&
         AB_FindPositionTicketByIdentifier(basket.members[i].position_identifier)==0)
         AB_BasketMarkExternalMemberExit(basket,basket.members[i].position_identifier);
   AB_BasketUpdatePhaseAfterMemberExit(basket);
   if(basket.phase==AB_BASKET_NONE)
      return 0;
   int submitted=0;
   bool activated=AB_TryActivateBasketExitV32_11(basket,tick);
   bool reached=AB_BasketZeroReached(basket,tick);
   if(basket.exit_mode!=AB_BASKET_EXIT_TP && !activated)
      return 0;
   if(basket.exit_mode==AB_BASKET_EXIT_TRAILING &&
      basket.phase==AB_BASKET_EXITING)
     {
      if(basket.direction==POSITION_TYPE_BUY)
         basket.favorable_extreme=MathMax(basket.favorable_extreme,tick.bid);
      else
         basket.favorable_extreme=MathMin(basket.favorable_extreme,tick.ask);
     }
   bool should_close=basket.phase==AB_BASKET_FORCE_CLOSING ||
      (basket.exit_mode==AB_BASKET_EXIT_TRAILING &&
       basket.phase==AB_BASKET_EXITING &&
       AB_BasketTrailingExitTriggered(basket,tick,trailing_distance_micro_points,rules));
   if(basket.exit_mode==AB_BASKET_EXIT_TP)
     {
      for(int i=0;i<basket.member_count;i++)
        {
         if(!basket.members[i].active || basket.members[i].pending_operation_id!=0)
            continue;
         ulong ticket=AB_FindPositionTicketByIdentifier(basket.members[i].position_identifier);
         if(ticket==0 || !PositionSelectByTicket(ticket) ||
            ledger.HasInFlightForEntity(basket.members[i].entity_id))
            continue;
         if(reached && !basket.members[i].tp_installed)
           {
            double volume=PositionGetDouble(POSITION_VOLUME);
            MqlTradeRequest close_request;
            if(!AB_PreparePositionCloseRequest(basket.symbol,ticket,basket.direction,volume,
                                                tick,slippage_micro_points,close_request))
               continue;
            ulong close_operation_id=0;
            AB_TRADE_RESULT_KIND close_result_kind=AB_TRADE_RESULT_UNKNOWN;
            if(AB_SendTradeRequest(close_request,ledger,basket.members[i].entity_id,volume,
                                   close_operation_id,close_result_kind))
              {
               AB_BasketMarkOperationPending(basket,i,close_operation_id,3);
               submitted++;
              }
            continue;
           }
         if(basket.members[i].tp_installed)
            continue;
         double current_sl=0.0;
         current_sl=PositionGetDouble(POSITION_SL);
         if(!AB_IsBasketTPUsable(basket,rules,tick,basket.zero_price))
            continue;
         MqlTradeRequest request;
         if(!AB_PreparePositionTPRequest(basket.symbol,ticket,current_sl,basket.zero_price,request))
            continue;
         ulong operation_id=0;
         AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
         if(AB_SendTradeRequest(request,ledger,basket.members[i].entity_id,0.0,
                                operation_id,result_kind))
           {
            AB_BasketMarkOperationPending(basket,i,operation_id,1);
            submitted++;
           }
        }
     }
   if(basket.exit_mode==AB_BASKET_EXIT_ONE_SHOT_SL &&
      basket.phase==AB_BASKET_EXITING)
     {
      for(int i=0;i<basket.member_count;i++)
        {
         if(!basket.members[i].active || basket.members[i].one_shot_sl_installed ||
            basket.members[i].pending_operation_id!=0)
            continue;
         ulong ticket=AB_FindPositionTicketByIdentifier(basket.members[i].position_identifier);
         if(ticket==0 || ledger.HasInFlightForEntity(basket.members[i].entity_id))
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         double current_sl=PositionGetDouble(POSITION_SL);
         double target_sl=basket.zero_price;
         bool stronger=basket.direction==POSITION_TYPE_BUY
            ? current_sl>=target_sl && current_sl>0.0
            : current_sl<=target_sl && current_sl>0.0;
         if(stronger)
           {
            basket.members[i].one_shot_sl_installed=true;
            continue;
           }
         AB_NormalPositionState position;
         ZeroMemory(position);
         position.position_type=basket.direction;
         position.current_sl=current_sl;
         if(!AB_IsSLTightening(position,target_sl) ||
            !AB_IsSLTargetUsable(position,rules,tick,target_sl))
            continue;
         MqlTradeRequest request;
         if(!AB_PreparePositionSLTPRequest(basket.symbol,ticket,target_sl,
                                            PositionGetDouble(POSITION_TP),request))
            continue;
         ulong operation_id=0;
         AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
         if(AB_SendTradeRequest(request,ledger,basket.members[i].entity_id,0.0,
                                operation_id,result_kind))
           {
            AB_BasketMarkOperationPending(basket,i,operation_id,2);
            submitted++;
           }
        }
      bool all_installed=true;
      for(int i=0;i<basket.member_count;i++)
         if(basket.members[i].active && !basket.members[i].one_shot_sl_installed)
            all_installed=false;
      if(!all_installed && AB_BasketOneShotReverseReachedV32_11(
            basket,tick,reverse_close_micro_points,rules))
        {
         basket.force_close=true;
         basket.phase=AB_BASKET_FORCE_CLOSING;
         should_close=true;
        }
     }
   if(should_close)
     {
      for(int i=0;i<basket.member_count;i++)
        {
         if(!basket.members[i].active || basket.members[i].pending_operation_id!=0)
            continue;
         ulong ticket=AB_FindPositionTicketByIdentifier(basket.members[i].position_identifier);
         if(ticket==0 || !PositionSelectByTicket(ticket) || ledger.HasInFlightForEntity(basket.members[i].entity_id))
            continue;
         double volume=PositionGetDouble(POSITION_VOLUME);
         MqlTradeRequest request;
         if(!AB_PreparePositionCloseRequest(basket.symbol,ticket,basket.direction,volume,
                                             tick,slippage_micro_points,request))
            continue;
         ulong operation_id=0;
         AB_TRADE_RESULT_KIND result_kind=AB_TRADE_RESULT_UNKNOWN;
         if(AB_SendTradeRequest(request,ledger,basket.members[i].entity_id,volume,
                                operation_id,result_kind))
           {
            AB_BasketMarkOperationPending(basket,i,operation_id,3);
            submitted++;
           }
        }
     }
   return submitted;
  }

#endif
