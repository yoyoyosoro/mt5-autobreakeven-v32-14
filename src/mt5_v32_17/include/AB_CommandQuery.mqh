#ifndef AB_COMMAND_QUERY_MQH
#define AB_COMMAND_QUERY_MQH

#include "AB_Types.mqh"

enum AB_COMMAND_ID
  {
   AB_COMMAND_NONE = 0,
   AB_COMMAND_JOIN,
   AB_COMMAND_EXIT_MANAGEMENT,
   AB_COMMAND_EXIT,
   AB_COMMAND_SELECT_SL_MODE,
   AB_COMMAND_STOP_TRAILING,
   AB_COMMAND_MANUAL_CLOSE,
   AB_COMMAND_TRIGGER_NEXT_LEVEL,
   AB_COMMAND_BASKET_LONG,
   AB_COMMAND_BASKET_SHORT,
   AB_COMMAND_BASKET_LONG_NO_LADDER,
   AB_COMMAND_BASKET_SHORT_NO_LADDER,
   AB_COMMAND_BASKET_CANCEL,
   AB_COMMAND_STRADDLE_START,
   AB_COMMAND_STRADDLE_SETTLE,
   AB_COMMAND_STRADDLE_CANCEL_ORDERS
  };

struct AB_CommandRequest
  {
   AB_COMMAND_ID command;
   AB_ManagedEntityId entity_id;
   AB_SL_MODE sl_mode;
   double ratio_percent;
   int distance_micro_points;
   ulong position_ticket;
  };

struct AB_CommandResponse
  {
   AB_COMMAND_RESULT result;
   ulong operation_id;
   ulong state_version;
   AB_ERROR_CODE error;
  };

struct AB_EngineSnapshot
  {
   ulong state_version;
   int managed_normal_count;
   int managed_straddle_count;
   int unmanaged_position_count;
   int visible_ladder_count;
   int visible_basket_count;
   bool recovery_gate;
  };

AB_CommandResponse AB_RejectCommand(const AB_ERROR_CODE error,
                                    const ulong state_version)
  {
   AB_CommandResponse response;
   response.result=AB_COMMAND_REJECTED;
   response.operation_id=0;
   response.state_version=state_version;
   response.error=error;
   return response;
  }

AB_CommandResponse AB_AcceptCommand(const ulong state_version)
  {
   AB_CommandResponse response;
   response.result=AB_COMMAND_ACCEPTED;
   response.operation_id=0;
   response.state_version=state_version;
   response.error=AB_ERROR_NONE;
   return response;
  }

AB_EngineSnapshot AB_EmptyEngineSnapshot(const ulong state_version,
                                         const bool recovery_gate)
  {
   AB_EngineSnapshot snapshot;
   snapshot.state_version=state_version;
   snapshot.managed_normal_count=0;
   snapshot.managed_straddle_count=0;
   snapshot.unmanaged_position_count=0;
   snapshot.visible_ladder_count=0;
   snapshot.visible_basket_count=0;
   snapshot.recovery_gate=recovery_gate;
   return snapshot;
  }

#endif
