#ifndef AB_SYMBOL_RULES_MQH
#define AB_SYMBOL_RULES_MQH

#include "AB_Types.mqh"

double AB_MicroPointDistance(const AB_SymbolRules &rules,const double micro_points)
  {
   return micro_points*rules.point;
  }

double AB_Tolerance(const double step)
  {
   return MathMax(step*1.0e-8,1.0e-12);
  }

bool AB_IsTickAligned(const double price,const double tick_size)
  {
   if(tick_size<=0.0)
      return false;
   double steps=price/tick_size;
   return MathAbs(steps-MathRound(steps))<=AB_Tolerance(tick_size);
  }

double AB_AlignPriceForDirection(const double price,
                                 const double tick_size,
                                 const AB_PRICE_DIRECTION direction)
  {
   if(tick_size<=0.0)
      return price;
   double steps=price/tick_size;
   if(direction==AB_PRICE_BUY)
      return MathFloor(steps+AB_Tolerance(tick_size))*tick_size;
   return MathCeil(steps-AB_Tolerance(tick_size))*tick_size;
  }

double AB_NormalizeVolumeDown(const double requested,const double volume_step)
  {
   if(requested<=0.0 || volume_step<=0.0)
      return 0.0;
   double steps=MathFloor((requested+AB_Tolerance(volume_step))/volume_step);
   return MathMax(0.0,steps*volume_step);
  }

bool AB_IsVolumeUsable(const double volume,
                       const AB_SymbolRules &rules)
  {
   if(volume<=0.0 || rules.volume_step<=0.0)
      return false;
   if(volume+AB_Tolerance(rules.volume_min)<rules.volume_min)
      return false;
   if(rules.volume_max>0.0 && volume-rules.volume_max>AB_Tolerance(rules.volume_max))
      return false;
   double steps=volume/rules.volume_step;
   return MathAbs(steps-MathRound(steps))<=AB_Tolerance(rules.volume_step);
  }

bool AB_IsPartialCloseUsable(const double current_volume,
                             const double requested_volume,
                             const AB_SymbolRules &rules)
  {
   double close_volume=AB_NormalizeVolumeDown(requested_volume,rules.volume_step);
   if(!AB_IsVolumeUsable(close_volume,rules))
      return false;
   double remainder=current_volume-close_volume;
   if(remainder<0.0)
      return false;
   if(remainder<=AB_Tolerance(rules.volume_step))
      return true;
   return AB_IsVolumeUsable(remainder,rules);
  }

bool AB_LoadSymbolRules(const string symbol,AB_SymbolRules &rules)
  {
   rules.symbol=symbol;
   rules.point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   rules.tick_size=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   rules.digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   rules.volume_min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   rules.volume_max=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   rules.volume_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   rules.volume_limit=SymbolInfoDouble(symbol,SYMBOL_VOLUME_LIMIT);
   rules.stops_level_points=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   rules.freeze_level_points=(int)SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   return rules.point>0.0 && rules.tick_size>0.0 && rules.volume_min>0.0 && rules.volume_step>0.0;
  }

#endif
