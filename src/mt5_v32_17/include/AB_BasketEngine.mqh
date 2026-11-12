#ifndef AB_BASKET_ENGINE_MQH
#define AB_BASKET_ENGINE_MQH

#include "AB_Types.mqh"
#include "AB_SymbolRules.mqh"

enum AB_BASKET_EXIT_MODE
  {
   AB_BASKET_EXIT_TP = 0,
   AB_BASKET_EXIT_TRAILING,
   AB_BASKET_EXIT_ONE_SHOT_SL
  };

struct AB_BasketMember
  {
   AB_ManagedEntityId entity_id;
   ulong position_identifier;
   double volume;
   double open_price;
   double frozen_net_result;
   bool active;
   bool combo_sl_suppressed;
   bool tp_installed;
   double owned_tp;
   bool one_shot_sl_installed;
   ulong pending_operation_id;
   int pending_kind;
  };

struct AB_BasketLadderEvent
  {
   double price;
   double close_volume;
  };

struct AB_BasketSnapshot
  {
   AB_ManagedEntityId basket_id;
   AB_BASKET_PHASE phase;
   AB_BASKET_EXIT_MODE exit_mode;
   ENUM_POSITION_TYPE direction;
   string symbol;
   bool no_ladder;
   AB_BasketMember members[64];
   int member_count;
   AB_BasketLadderEvent ladder_events[640];
   int ladder_event_count;
   double zero_price;
   double frozen_bid;
   double frozen_ask;
   double frozen_spread;
   double frozen_point;
   double frozen_tick_size;
   double frozen_tick_value;
   double frozen_net_result;
   double favorable_extreme;
   bool trailing_paused;
   bool force_close;
  };

bool AB_ComputeBasketZeroPrice(const AB_BasketSnapshot &basket,
                               const AB_SymbolRules &rules,
                               double &zero_price)
  {
   if(basket.member_count<=0 || basket.frozen_tick_size<=0.0 ||
      basket.frozen_tick_value<=0.0 || basket.frozen_bid<=0.0 || basket.frozen_ask<=0.0)
      return false;
   double slope=0.0;
   double net_result=0.0;
   for(int i=0;i<basket.member_count;i++)
     {
      if(!basket.members[i].active || basket.members[i].volume<=0.0)
         continue;
      slope+=basket.members[i].volume*basket.frozen_tick_value/basket.frozen_tick_size;
      net_result+=basket.members[i].frozen_net_result;
     }
   if(slope<=0.0)
      return false;
   double execution_price=basket.direction==POSITION_TYPE_BUY ? basket.frozen_bid : basket.frozen_ask;
   double cursor=execution_price;
   double raw=0.0;
   for(int i=0;i<basket.ladder_event_count;i++)
     {
      double move=basket.direction==POSITION_TYPE_BUY
         ? basket.ladder_events[i].price-cursor
         : cursor-basket.ladder_events[i].price;
      double event_net=net_result+slope*MathMax(0.0,move);
      if(net_result<0.0 && event_net>=0.0)
        {
         double required=-net_result/slope;
         raw=basket.direction==POSITION_TYPE_BUY ? cursor+required : cursor-required;
         break;
        }
      net_result=event_net;
      cursor=basket.ladder_events[i].price;
      slope-=basket.ladder_events[i].close_volume*basket.frozen_tick_value/basket.frozen_tick_size;
      if(slope<=0.0)
         return false;
     }
   if(raw<=0.0)
     {
      double required=-net_result/slope;
      raw=basket.direction==POSITION_TYPE_BUY ? cursor+required : cursor-required;
     }
   zero_price=AB_AlignPriceForDirection(raw,basket.frozen_tick_size,
      basket.direction==POSITION_TYPE_BUY ? AB_PRICE_BUY : AB_PRICE_SELL);
   return zero_price>0.0;
  }

void AB_SortBasketLadderEvents(AB_BasketSnapshot &basket)
  {
   for(int i=0;i<basket.ladder_event_count-1;i++)
      for(int j=i+1;j<basket.ladder_event_count;j++)
        {
         bool swap=basket.direction==POSITION_TYPE_BUY
            ? basket.ladder_events[j].price<basket.ladder_events[i].price
            : basket.ladder_events[j].price>basket.ladder_events[i].price;
         if(swap)
           {
            AB_BasketLadderEvent event=basket.ladder_events[i];
            basket.ladder_events[i]=basket.ladder_events[j];
            basket.ladder_events[j]=event;
           }
        }
  }

double AB_FrozenPositionCommission(const ulong position_identifier)
  {
   if(position_identifier==0 || !HistorySelect(0,TimeCurrent()))
      return 0.0;
   double commission=0.0;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal!=0 && (ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID)==position_identifier)
         commission+=HistoryDealGetDouble(deal,DEAL_COMMISSION);
     }
   return commission;
  }

bool AB_BasketTrailingExitTriggered(const AB_BasketSnapshot &basket,
                                    const MqlTick &tick,
                                    const int distance_micro_points,
                                    const AB_SymbolRules &rules)
  {
   if(basket.exit_mode!=AB_BASKET_EXIT_TRAILING || basket.trailing_paused || distance_micro_points<=0)
      return false;
   double distance=AB_MicroPointDistance(rules,distance_micro_points);
   double trigger=basket.direction==POSITION_TYPE_BUY
      ? basket.favorable_extreme-distance
      : basket.favorable_extreme+distance;
   double execution_price=basket.direction==POSITION_TYPE_BUY ? tick.bid : tick.ask;
   return basket.direction==POSITION_TYPE_BUY ? execution_price<=trigger : execution_price>=trigger;
  }

bool AB_BasketZeroReached(const AB_BasketSnapshot &basket,const MqlTick &tick)
  {
   if(basket.zero_price<=0.0)
      return false;
   return basket.direction==POSITION_TYPE_BUY ? tick.bid>=basket.zero_price
                                              : tick.ask<=basket.zero_price;
  }

void AB_BasketMemberExited(AB_BasketSnapshot &basket,const ulong position_identifier)
  {
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].position_identifier==position_identifier)
         basket.members[i].active=false;
  }

void AB_BasketMarkOperationPending(AB_BasketSnapshot &basket,
                                   const int member_index,
                                   const ulong operation_id,
                                   const int kind)
  {
   if(member_index<0 || member_index>=basket.member_count)
      return;
   basket.members[member_index].pending_operation_id=operation_id;
   basket.members[member_index].pending_kind=kind;
  }

bool AB_BasketCompleteOperation(AB_BasketSnapshot &basket,const ulong operation_id)
  {
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].pending_operation_id==operation_id)
        {
         if(basket.members[i].pending_kind==1)
           {
            basket.members[i].tp_installed=true;
            basket.members[i].owned_tp=basket.zero_price;
           }
         else if(basket.members[i].pending_kind==2)
            basket.members[i].one_shot_sl_installed=true;
         else if(basket.members[i].pending_kind==3)
            basket.members[i].active=false;
         else if(basket.members[i].pending_kind==4)
           {
            basket.members[i].tp_installed=false;
            basket.members[i].owned_tp=0.0;
           }
         basket.members[i].pending_operation_id=0;
         basket.members[i].pending_kind=0;
         return true;
        }
   return false;
  }

bool AB_BasketRejectOperation(AB_BasketSnapshot &basket,const ulong operation_id)
  {
   if(operation_id==0)
      return false;
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].pending_operation_id==operation_id)
        {
         basket.members[i].pending_operation_id=0;
         basket.members[i].pending_kind=0;
         return true;
        }
   return false;
  }

void AB_BasketRequestCancel(AB_BasketSnapshot &basket)
  {
   if(basket.phase!=AB_BASKET_NONE)
      basket.phase=AB_BASKET_CANCELLING;
  }

void AB_BasketMarkExternalMemberExit(AB_BasketSnapshot &basket,
                                     const ulong position_identifier)
  {
   AB_BasketMemberExited(basket,position_identifier);
  }

void AB_BasketUpdatePhaseAfterMemberExit(AB_BasketSnapshot &basket)
  {
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].active)
         return;
   basket.phase=AB_BASKET_NONE;
  }

bool AB_BasketHasLiveMember(const AB_BasketSnapshot &basket)
  {
   for(int i=0;i<basket.member_count;i++)
     {
      if(!basket.members[i].active)
         continue;
      for(int p=0;p<PositionsTotal();p++)
        {
         ulong ticket=PositionGetTicket(p);
         if(ticket!=0 && PositionSelectByTicket(ticket) &&
            (ulong)PositionGetInteger(POSITION_IDENTIFIER)==basket.members[i].position_identifier)
            return true;
        }
     }
   return false;
  }

void AB_ClearEndedBasket(AB_BasketSnapshot &basket)
  {
   if(basket.phase!=AB_BASKET_NONE && !AB_BasketHasLiveMember(basket))
      ZeroMemory(basket);
  }

bool AB_BasketSuspendsNormalSL(const AB_BasketSnapshot &basket,
                               const ulong position_identifier)
  {
   if(position_identifier==0 || basket.phase==AB_BASKET_NONE)
      return false;
   bool phase_suspends=basket.phase==AB_BASKET_CANCELLING ||
      basket.phase==AB_BASKET_SWITCHING || basket.phase==AB_BASKET_FORCE_CLOSING;
   bool mode_suspends=basket.exit_mode!=AB_BASKET_EXIT_TP;
   if(!phase_suspends && !mode_suspends)
      return false;
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].active &&
         basket.members[i].position_identifier==position_identifier)
         return !basket.members[i].combo_sl_suppressed;
   return false;
  }

bool AB_BasketSuspendsNormalLadder(const AB_BasketSnapshot &basket,
                                   const ulong position_identifier)
  {
   if(position_identifier==0 || basket.phase==AB_BASKET_NONE || !basket.no_ladder)
      return false;
   for(int i=0;i<basket.member_count;i++)
      if(basket.members[i].active &&
         basket.members[i].position_identifier==position_identifier)
         return true;
   return false;
  }

#endif
