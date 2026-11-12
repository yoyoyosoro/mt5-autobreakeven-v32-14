#ifndef AB_TYPES_MQH
#define AB_TYPES_MQH

struct AB_ManagedEntityId
  {
   ulong value;
  };

enum AB_SL_MODE
  {
   AB_SL_NONE = 0,
   AB_SL_M1,
   AB_SL_ENTRY,
   AB_SL_TRAILING_1,
   AB_SL_TRAILING_2,
   AB_SL_TRAILING_3,
   AB_SL_TRAILING_4,
   AB_SL_STOPPED
  };

enum AB_BASKET_PHASE
  {
   AB_BASKET_NONE = 0,
   AB_BASKET_ACTIVE,
   AB_BASKET_EXITING,
   AB_BASKET_CANCELLING,
   AB_BASKET_SWITCHING,
   AB_BASKET_FORCE_CLOSING
  };

enum AB_OPERATION_STATE
  {
   AB_OPERATION_NONE = 0,
   AB_OPERATION_ACCEPTED,
   AB_OPERATION_PENDING,
   AB_OPERATION_COMPLETED,
   AB_OPERATION_UNKNOWN,
   AB_OPERATION_TEMPORARY,
   AB_OPERATION_REJECTED
  };

enum AB_TRADE_RESULT_KIND
  {
   AB_TRADE_RESULT_COMPLETED = 0,
   AB_TRADE_RESULT_PROCESSING,
   AB_TRADE_RESULT_UNKNOWN,
   AB_TRADE_RESULT_TEMPORARY,
   AB_TRADE_RESULT_REJECTED
  };

enum AB_OPERATION_PURPOSE
  {
   AB_PURPOSE_CLOSE = 0,
   AB_PURPOSE_SLTP,
   AB_PURPOSE_PENDING_ORDER,
   AB_PURPOSE_CANCEL
  };

enum AB_COMMAND_RESULT
  {
   AB_COMMAND_ACCEPTED = 0,
   AB_COMMAND_REJECTED,
   AB_COMMAND_PENDING
  };

enum AB_ERROR_CODE
  {
   AB_ERROR_NONE = 0,
   AB_ERROR_INVALID_ARGUMENT,
   AB_ERROR_INVALID_SYMBOL_RULE,
   AB_ERROR_VOLUME_TOO_SMALL,
   AB_ERROR_INVALID_REMAINDER,
   AB_ERROR_TEMPORARY_RESTRICTION,
   AB_ERROR_REQUEST_UNKNOWN,
   AB_ERROR_NOT_MANAGED,
   AB_ERROR_CONFLICT
  };

enum AB_PRICE_DIRECTION
  {
   AB_PRICE_BUY = 0,
   AB_PRICE_SELL
  };

struct AB_LadderLevelInput
  {
   double distance_micro_points;
   double close_ratio_percent;
  };

struct AB_LadderConfig
  {
   AB_LadderLevelInput normal[10];
   AB_LadderLevelInput breakout[10];
  };

struct AB_SymbolRules
  {
   string symbol;
   double point;
   double tick_size;
   int digits;
   double volume_min;
   double volume_max;
   double volume_step;
   double volume_limit;
   int stops_level_points;
   int freeze_level_points;
  };

struct AB_OperationRecord
  {
   ulong operation_id;
   ulong request_id;
   ulong order_ticket;
   AB_ManagedEntityId entity_id;
   AB_OPERATION_STATE state;
   AB_OPERATION_PURPOSE purpose;
   bool deal_required;
   double requested_volume;
   double completed_volume;
   datetime created_at;
  };

#endif
