#ifndef AB_LADDER_ENGINE_MQH
#define AB_LADDER_ENGINE_MQH

#include "AB_Types.mqh"
#include "AB_SymbolRules.mqh"

struct AB_LadderLevelState
  {
   bool enabled;
   bool completed;
   bool pending_request;
   ulong pending_operation_id;
   double distance_micro_points;
   double ratio_percent;
   double planned_volume;
  };

struct AB_LadderPositionState
  {
   AB_ManagedEntityId entity_id;
   double original_volume;
   double current_volume;
   double profit_micro_points;
   AB_LadderLevelState levels[10];
  };

bool AB_IsLadderLevelEnabled(const AB_LadderLevelInput &level_input)
  {
   return level_input.distance_micro_points>0.0 && level_input.close_ratio_percent>0.0;
  }

void AB_LoadLadderLevels(AB_LadderLevelState &levels[],
                         const AB_LadderLevelInput &inputs[])
  {
   int count=MathMin(ArraySize(levels),ArraySize(inputs));
   for(int i=0;i<count;i++)
     {
      levels[i].enabled=AB_IsLadderLevelEnabled(inputs[i]);
      levels[i].completed=false;
      levels[i].pending_request=false;
      levels[i].pending_operation_id=0;
      levels[i].distance_micro_points=inputs[i].distance_micro_points;
      levels[i].ratio_percent=inputs[i].close_ratio_percent;
      levels[i].planned_volume=0.0;
     }
  }

bool AB_LadderPriceStillTriggered(const AB_LadderLevelState &level,
                                  const double current_profit_micro_points)
  {
   return level.enabled && !level.completed && !level.pending_request &&
          current_profit_micro_points>=level.distance_micro_points;
  }

double AB_ComputeLadderCloseVolume(const AB_LadderPositionState &position,
                                   const AB_LadderLevelState &level,
                                   const AB_SymbolRules &rules)
  {
   if(!level.enabled || level.completed || position.original_volume<=0.0)
      return 0.0;
   double requested=position.original_volume*level.ratio_percent/100.0;
   double rounded=AB_NormalizeVolumeDown(requested,rules.volume_step);
   if(!AB_IsPartialCloseUsable(position.current_volume,rounded,rules))
      return 0.0;
   return rounded;
  }

void AB_MarkLadderRequestPending(AB_LadderLevelState &level,const double planned_volume)
  {
   level.pending_request=true;
   level.planned_volume=planned_volume;
  }

void AB_MarkLadderOperationPending(AB_LadderLevelState &level,
                                   const double planned_volume,
                                   const ulong operation_id)
  {
   AB_MarkLadderRequestPending(level,planned_volume);
   level.pending_operation_id=operation_id;
  }

void AB_MarkLadderDealCompleted(AB_LadderLevelState &level)
  {
   level.pending_request=false;
   level.pending_operation_id=0;
   level.completed=true;
  }

void AB_MarkLadderRequestUnknown(AB_LadderLevelState &level)
  {
   level.pending_request=true;
  }

class AB_LadderBook
  {
private:
   AB_LadderPositionState m_items[128];
   int m_count;

   int Find(const AB_ManagedEntityId &entity_id)
     {
      for(int i=0;i<m_count;i++)
         if(m_items[i].entity_id.value==entity_id.value)
            return i;
      return -1;
     }

public:
   AB_LadderBook(void)
     {
      m_count=0;
     }

   int Count(void) const { return m_count; }

   bool GetAt(const int index,AB_LadderPositionState &state)
     {
      if(index<0 || index>=m_count)
         return false;
      state=m_items[index];
      return true;
     }

   bool Ensure(const AB_ManagedEntityId &entity_id,
               const double original_volume,
               const double current_volume,
               const AB_LadderLevelInput &inputs[])
     {
      int index=Find(entity_id);
      if(index<0)
        {
         if(m_count>=128)
            return false;
         index=m_count++;
         ZeroMemory(m_items[index]);
         m_items[index].entity_id=entity_id;
         AB_LoadLadderLevels(m_items[index].levels,inputs);
        }
      m_items[index].original_volume=original_volume;
      m_items[index].current_volume=current_volume;
      return true;
     }

   bool Get(const AB_ManagedEntityId &entity_id,AB_LadderPositionState &state)
     {
      int index=Find(entity_id);
      if(index<0)
         return false;
      state=m_items[index];
      return true;
    }

   bool ResetUnfinishedTriggers(const AB_ManagedEntityId &entity_id)
     {
      int index=Find(entity_id);
      if(index<0)
         return false;
      for(int level=0;level<10;level++)
         if(!m_items[index].levels[level].completed &&
            m_items[index].levels[level].pending_operation_id==0)
           {
            m_items[index].levels[level].pending_request=false;
            m_items[index].levels[level].planned_volume=0.0;
           }
      return true;
     }

   bool Restore(const AB_LadderPositionState &state)
     {
      if(state.entity_id.value==0 || m_count>=128)
         return false;
      int index=Find(state.entity_id);
      if(index<0)
         index=m_count++;
      m_items[index]=state;
      return true;
     }

   bool RemoveByEntity(const AB_ManagedEntityId &entity_id)
     {
      int index=Find(entity_id);
      if(index<0)
         return false;
      for(int i=index;i<m_count-1;i++)
         m_items[i]=m_items[i+1];
      m_count--;
      return true;
     }

   bool MarkPending(const AB_ManagedEntityId &entity_id,
                   const int level_index,
                   const double planned_volume,
                   const ulong operation_id)
     {
      int index=Find(entity_id);
      if(index<0 || level_index<0 || level_index>=10)
         return false;
      AB_MarkLadderOperationPending(m_items[index].levels[level_index],planned_volume,operation_id);
      return true;
     }

   bool CompleteByOperation(const ulong operation_id)
     {
      if(operation_id==0)
         return false;
      for(int i=0;i<m_count;i++)
         for(int level=0;level<10;level++)
            if(m_items[i].levels[level].pending_operation_id==operation_id)
              {
               AB_MarkLadderDealCompleted(m_items[i].levels[level]);
               return true;
              }
      return false;
     }

   bool RejectByOperation(const ulong operation_id)
     {
      if(operation_id==0)
         return false;
      for(int i=0;i<m_count;i++)
         for(int level=0;level<10;level++)
            if(m_items[i].levels[level].pending_operation_id==operation_id)
              {
               m_items[i].levels[level].pending_request=false;
               m_items[i].levels[level].pending_operation_id=0;
               m_items[i].levels[level].planned_volume=0.0;
               return true;
              }
      return false;
     }
  };

#endif
