#ifndef AB_NORMAL_ENGINE_MQH
#define AB_NORMAL_ENGINE_MQH

#include "AB_Types.mqh"
#include "AB_SymbolRules.mqh"

struct AB_NormalPositionState
  {
   AB_ManagedEntityId entity_id;
   ulong position_identifier;
   ulong current_ticket;
   ENUM_POSITION_TYPE position_type;
   string symbol;
   datetime open_time;
   double open_price;
   double original_volume;
   double current_volume;
   AB_SL_MODE sl_mode;
   int trailing_distance_micro_points;
   bool auto_sl_done;
   bool manual_close_pending;
   double manual_close_volume;
   double current_sl;
   double current_tp;
  };

bool AB_IsNormalSLMode(const AB_SL_MODE mode)
  {
   return mode==AB_SL_M1 || mode==AB_SL_ENTRY ||
          mode==AB_SL_TRAILING_1 || mode==AB_SL_TRAILING_2 ||
          mode==AB_SL_TRAILING_3 || mode==AB_SL_TRAILING_4 ||
          mode==AB_SL_STOPPED;
  }

double AB_ComputeEntrySL(const AB_NormalPositionState &position,
                         const AB_SymbolRules &rules,
                         const double offset_micro_points)
  {
   double offset=AB_MicroPointDistance(rules,offset_micro_points);
   return position.position_type==POSITION_TYPE_BUY
      ? position.open_price+offset
      : position.open_price-offset;
  }

bool AB_ComputeM1SL(const AB_NormalPositionState &position,
                    const AB_SymbolRules &rules,
                    const int offset_micro_points,
                    double &target_sl)
  {
   int shift=iBarShift(position.symbol,PERIOD_M1,position.open_time,false);
   if(shift<0)
      return false;
   double base=position.position_type==POSITION_TYPE_BUY
      ? iLow(position.symbol,PERIOD_M1,shift)
      : iHigh(position.symbol,PERIOD_M1,shift);
   if(base<=0.0)
      return false;
   double offset=AB_MicroPointDistance(rules,offset_micro_points);
   target_sl=position.position_type==POSITION_TYPE_BUY ? base+offset : base-offset;
   return true;
  }

bool AB_ComputeTrailingSL(const AB_NormalPositionState &position,
                          const AB_SymbolRules &rules,
                          const MqlTick &tick,
                          const int distance_micro_points,
                          double &target_sl)
  {
   if(distance_micro_points<=0 || rules.point<=0.0)
      return false;
   double distance=AB_MicroPointDistance(rules,distance_micro_points);
   target_sl=position.position_type==POSITION_TYPE_BUY
      ? tick.bid-distance
      : tick.ask+distance;
   return target_sl>0.0;
  }

bool AB_AutoBreakevenTriggered(const AB_NormalPositionState &position,
                               const AB_SymbolRules &rules,
                               const MqlTick &tick,
                               const int trigger_micro_points)
  {
   if(trigger_micro_points<=0 || rules.point<=0.0 || position.auto_sl_done)
      return false;
   double distance=position.position_type==POSITION_TYPE_BUY
      ? tick.bid-position.open_price
      : position.open_price-tick.ask;
   return distance+AB_Tolerance(rules.point)>=AB_MicroPointDistance(rules,trigger_micro_points);
  }

bool AB_IsSLTightening(const AB_NormalPositionState &position,
                       const double target_sl)
  {
   if(target_sl<=0.0)
      return false;
   if(position.current_sl<=0.0)
      return true;
   return position.position_type==POSITION_TYPE_BUY
      ? target_sl>position.current_sl+AB_Tolerance(target_sl)
      : target_sl<position.current_sl-AB_Tolerance(target_sl);
  }

bool AB_IsSLTargetUsable(const AB_NormalPositionState &position,
                         const AB_SymbolRules &rules,
                         const MqlTick &tick,
                         const double target_sl)
  {
   if(target_sl<=0.0 || rules.point<=0.0)
      return false;
   double stop_distance=position.position_type==POSITION_TYPE_BUY
      ? tick.bid-target_sl
      : target_sl-tick.ask;
   return stop_distance>=rules.stops_level_points*rules.point;
  }

double AB_ManualCloseVolume(const AB_NormalPositionState &position,
                            const AB_SymbolRules &rules,
                            const double ratio_percent,
                            const bool close_all)
  {
   double requested=close_all ? position.original_volume
      : position.original_volume*MathMax(0.0,ratio_percent)/100.0;
   double rounded=AB_NormalizeVolumeDown(requested,rules.volume_step);
   if(!AB_IsPartialCloseUsable(position.original_volume,rounded,rules))
      return 0.0;
   return rounded;
  }

class AB_NormalEngine
  {
private:
   AB_NormalPositionState m_position;

public:
   AB_NormalEngine(void)
     {
      ZeroMemory(m_position);
      m_position.sl_mode=AB_SL_NONE;
     }

   void Attach(const AB_NormalPositionState &position)
     {
      m_position=position;
     }

   bool SelectSLMode(const AB_SL_MODE mode,const int trailing_distance_micro_points)
     {
      if(!AB_IsNormalSLMode(mode))
         return false;
      m_position.sl_mode=mode;
      m_position.trailing_distance_micro_points=mode>=AB_SL_TRAILING_1 && mode<=AB_SL_TRAILING_4
         ? trailing_distance_micro_points : 0;
      m_position.manual_close_pending=false;
      return true;
     }

   bool StopTrailing(void)
     {
      if(m_position.sl_mode<AB_SL_TRAILING_1 || m_position.sl_mode>AB_SL_TRAILING_4)
         return false;
      m_position.sl_mode=AB_SL_STOPPED;
      m_position.trailing_distance_micro_points=0;
      return true;
     }

   bool IsAutomaticSLAllowed(void) const
     {
      return m_position.sl_mode!=AB_SL_STOPPED &&
             m_position.sl_mode!=AB_SL_ENTRY &&
             m_position.sl_mode!=AB_SL_M1;
     }

   bool StartManualClose(const double volume)
     {
      if(volume<=0.0 || m_position.manual_close_pending)
         return false;
      m_position.manual_close_pending=true;
      m_position.manual_close_volume=volume;
      return true;
     }

   void CompleteManualClose(void)
     {
      m_position.manual_close_pending=false;
      m_position.manual_close_volume=0.0;
     }

   AB_SL_MODE CurrentSLMode(void) const
     {
      return m_position.sl_mode;
     }
  };

#endif
