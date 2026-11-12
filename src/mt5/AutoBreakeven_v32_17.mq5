#define AB_EA_VERSION "32.17"

#property strict
#property version   AB_EA_VERSION
#property description "MT5 native rewrite of the approved v31.02 trading engine"

#resource "resources\\fonts\\Inter-Regular.ttf"
#resource "resources\\fonts\\Inter-Medium.ttf"
#resource "resources\\fonts\\Inter-SemiBold.ttf"

#include "include\AB_Types.mqh"
#include "include\AB_UiRefreshState.mqh"
#include "include\AB_SymbolRules.mqh"
#include "include\AB_OperationLedger.mqh"
#include "include\AB_TradeAdapter.mqh"
#include "include\AB_Persistence.mqh"
#include "include\AB_PositionRegistry.mqh"
#include "include\AB_NormalEngine.mqh"
#include "include\AB_LadderEngine.mqh"
#include "include\AB_StraddleEngine.mqh"
#include "include\AB_BasketEngine.mqh"
#include "include\AB_CommandQuery.mqh"
#include "include\AB_ChartView.mqh"
#include "include\AB_CanvasPanel.mqh"
#include "include\AB_PanelLogBuffer.mqh"
#include "include\AB_CanvasDynamicLayers.mqh"
#include "include\AB_Runtime.mqh"
#include "include\AB_BasketExit_v32_11.mqh"
#include "include\AB_StraddleLifecycle_v32_12.mqh"
#include "include\AB_NormalSafety_v32_06.mqh"
#include "include\AB_Recovery.mqh"
#include "include\AB_ObjectPersistence.mqh"

enum BasketExitMode
  {
   BASKET_EXIT_TP = 0,          // 保本TP
   BASKET_EXIT_TRAILING = 1,    // 追踪止损
   BASKET_EXIT_ONE_SHOT_SL = 2  // 单次保本SL
  };

input group "========== 1. 全局系统控制 =========="
input bool CurrentSymbolOnly = true;          // 仅限当前图表品种
input long Normal_Managed_Magic = 0;          // 普通订单魔术数；-1=全部普通订单
input int Slippage_MicroPoints = 30;          // 订单允许滑点(微点)
input int Spread_Buffer_MicroPoints = 10;     // 防扫针缓冲(微点,仅限K线模式有效)

input group "========== 2. 自动保本设置 (设0关闭) =========="
input int Normal_Auto_Trigger_MicroPoints = 500;       // 触发自动保本的盈利点数(微点)
input bool Normal_Use_M1_Mode = true;                   // True=M1 K线底部保本, False=开仓价保本
input int Normal_Auto_Entry_Offset_MicroPoints = -10;   // 偏移量(开仓价保本模式使用)
input int Normal_Auto_M1_Offset_MicroPoints = -10;      // 偏移量(M1 K线底部模式使用)

input group "========== 3. 按钮保本设置 (狙击普通最新单) =========="
input int Button_Entry_Offset_MicroPoints = 0;          // 按钮执行【开仓价保本】时的偏移量
input int Button_M1_Offset_MicroPoints = 0;             // 按钮执行【M1 K线保本】时的偏移量

input group "========== 4. 追踪止损设置 (普通订单最高优先级) =========="
input int Normal_Trail_1_MicroPoints = 50;              // 追踪设定值 1 (微点)
input int Normal_Trail_2_MicroPoints = 100;             // 追踪设定值 2 (微点)
input int Normal_Trail_3_MicroPoints = 200;             // 追踪设定值 3 (微点)
input int Normal_Trail_4_MicroPoints = 300;             // 追踪设定值 4 (微点)
input int Normal_Trail_Min_Step_MicroPoints = 5;        // 追踪止损最小移动距离(微点, 0=每次都移)

input group "========== 5. 手动平仓设置 (按原始仓位比例) =========="
input double Normal_Manual_Close_1_Ratio = 5.0;         // 手动平仓比例1(%)
input double Normal_Manual_Close_2_Ratio = 10.0;        // 手动平仓比例2(%)
input double Normal_Manual_Close_3_Ratio = 25.0;        // 手动平仓比例3(%)
input double Normal_Manual_Close_4_Ratio = 50.0;        // 手动平仓比例4(%)

input group "========== 6. 普通订单阶梯止盈 (微点/原始仓位比例/设0关闭/手数向下取整) =========="
input double Normal_L1_Distance = 300;                  // 普通第1阶距离(微点)
input double Normal_L1_Ratio = 20.0;                    // 普通第1阶平仓比例(%)
input double Normal_L2_Distance = 500;                  // 普通第2阶距离(微点)
input double Normal_L2_Ratio = 20.0;                    // 普通第2阶平仓比例(%)
input double Normal_L3_Distance = 800;                  // 普通第3阶距离(微点)
input double Normal_L3_Ratio = 20.0;                    // 普通第3阶平仓比例(%)
input double Normal_L4_Distance = 1200;                 // 普通第4阶距离(微点)
input double Normal_L4_Ratio = 0.0;                     // 普通第4阶平仓比例(%)
input double Normal_L5_Distance = 2000;                 // 普通第5阶距离(微点)
input double Normal_L5_Ratio = 0.0;                     // 普通第5阶平仓比例(%)
input double Normal_L6_Distance = 0;                    // 普通第6阶距离(微点)
input double Normal_L6_Ratio = 0.0;                     // 普通第6阶平仓比例(%)
input double Normal_L7_Distance = 0;                    // 普通第7阶距离(微点)
input double Normal_L7_Ratio = 0.0;                     // 普通第7阶平仓比例(%)
input double Normal_L8_Distance = 0;                    // 普通第8阶距离(微点)
input double Normal_L8_Ratio = 0.0;                     // 普通第8阶平仓比例(%)
input double Normal_L9_Distance = 0;                    // 普通第9阶距离(微点)
input double Normal_L9_Ratio = 0.0;                     // 普通第9阶平仓比例(%)
input double Normal_L10_Distance = 0;                   // 普通第10阶距离(微点)
input double Normal_L10_Ratio = 0.0;                    // 普通第10阶平仓比例(%)

input group "========== 7. 双向突破挂单 (独立参数/只按钮触发) =========="
input long Straddle_Magic = 8888;                       // 双向突破专属魔术数
input double Straddle_Lot_Size = 0.50;                  // 双向突破挂单手数
input int Straddle_Distance_MicroPoints = 1000;         // 上下挂单间隔(微点)
input int Straddle_Initial_SL_MicroPoints = 500;        // 初始止损距离(微点)
input int Straddle_BE_Trigger_MicroPoints = 1000;       // 锁损触发盈利距离(微点, 0关闭)
input int Straddle_BE_Lock_MicroPoints = 0;             // SL锁到开仓价 +/- 此距离(微点)

input group "========== 8. 双向突破独立阶梯止盈 (微点/原始仓位比例/设0关闭/手数向下取整) =========="
input double Breakout_L1_Distance = 0;                  // 突破第1阶距离(微点)
input double Breakout_L1_Ratio = 0.0;                   // 突破第1阶平仓比例(%)
input double Breakout_L2_Distance = 0;                  // 突破第2阶距离(微点)
input double Breakout_L2_Ratio = 0.0;                   // 突破第2阶平仓比例(%)
input double Breakout_L3_Distance = 0;                  // 突破第3阶距离(微点)
input double Breakout_L3_Ratio = 0.0;                   // 突破第3阶平仓比例(%)
input double Breakout_L4_Distance = 0;                  // 突破第4阶距离(微点)
input double Breakout_L4_Ratio = 0.0;                   // 突破第4阶平仓比例(%)
input double Breakout_L5_Distance = 0;                  // 突破第5阶距离(微点)
input double Breakout_L5_Ratio = 0.0;                   // 突破第5阶平仓比例(%)
input double Breakout_L6_Distance = 0;                  // 突破第6阶距离(微点)
input double Breakout_L6_Ratio = 0.0;                   // 突破第6阶平仓比例(%)
input double Breakout_L7_Distance = 0;                  // 突破第7阶距离(微点)
input double Breakout_L7_Ratio = 0.0;                   // 突破第7阶平仓比例(%)
input double Breakout_L8_Distance = 0;                  // 突破第8阶距离(微点)
input double Breakout_L8_Ratio = 0.0;                   // 突破第8阶平仓比例(%)
input double Breakout_L9_Distance = 0;                  // 突破第9阶距离(微点)
input double Breakout_L9_Ratio = 0.0;                   // 突破第9阶平仓比例(%)
input double Breakout_L10_Distance = 0;                 // 突破第10阶距离(微点)
input double Breakout_L10_Ratio = 0.0;                  // 突破第10阶平仓比例(%)

input group "========== 9. 阶梯止盈可视化 =========="
input TPLineDisplayMode TP_Line_Display_Mode = TP_LINE_SHORT; // 阶梯线显示模式

input group "========== 10. 组合保本止盈 =========="
input BasketExitMode Basket_Exit_Mode = BASKET_EXIT_TP;       // 组合保本止盈模式
input int Basket_Trailing_MicroPoints = 100;                  // 追踪止损距离(微点)
input int Basket_Reverse_Close_MicroPoints = 100;             // 反向强平距离(微点)

input group "========== 11. 正式操作面板 =========="
input PanelAnchor Panel_Default_Anchor = PANEL_TOP_LEFT;      // 面板默认锚定位置
input int Panel_Default_X = 10;                               // 面板横向偏移(像素)
input int Panel_Default_Y = 120;                              // 面板纵向偏移(像素)
input int Panel_Default_Width = 563;                          // 面板宽度(像素)
input int Panel_Default_Height = 1255;                        // 面板高度(像素)
input int Panel_Page_Vertical_Spacing = 24;                   // 面板页面纵向间距(像素)
input int Panel_Function_Button_Height = 36;                  // 页面功能按钮高度(像素)
input int TP_Label_Font_Size = 8;                             // 阶梯标签字号
input int Panel_Log_History = 7;                              // 交互提示保留条数
input PanelRedGreenMode Panel_Red_Green_Mode = PANEL_GREEN_UP; // 红绿显示模式

AB_LadderConfig g_ladder_config;
AB_SymbolRules g_symbol_rules;
AB_OperationLedger g_operation_ledger;
AB_Persistence g_persistence;
AB_PositionRegistry g_position_registry;
AB_LadderBook g_ladder_book;
AB_BreakoutRegistry g_breakout_registry;
AB_LadderBook g_breakout_ladder_book;
AB_StraddleState g_straddle_state;
AB_BasketSnapshot g_basket_long;
AB_BasketSnapshot g_basket_short;
int g_runtime_basket_trailing=0;
int g_runtime_basket_reverse_close=0;
BasketExitMode g_runtime_basket_mode=BASKET_EXIT_TP;
int g_runtime_auto_mode=0; // 0=M1, 1=entry, 2=off
bool g_runtime_ladder_enabled=true;
AB_AutoSLTriggerLatchBook g_auto_sl_trigger_latches;
ulong g_auto_sl_tick_cursor_msc=0;
int g_runtime_trail[4];
double g_runtime_close_ratio[4];
int g_runtime_tp_label_font_size=8;
int g_runtime_panel_x=0;
int g_runtime_panel_y=0;
int g_runtime_log_history=7;
datetime g_runtime_start;
AB_NormalEngine g_normal_engine;
AB_RuntimeState g_runtime_state;
AB_EngineSnapshot g_engine_snapshot;
ulong g_last_runtime_fingerprint=0;
AB_CanvasPanel g_panel;
AB_PanelLogBuffer g_panel_log;
AB_CanvasDynamicLayers g_dynamic_layers;
AB_UiRefreshState g_ui_refresh;
bool g_ui_initialized=false;
ulong g_selected_ticket=0;
ulong g_selected_position_identifier=0;
bool g_selected_breakout=false;
uint g_last_order_selection_click_ms=0;
uint g_last_panel_object_click_ms=0;
bool g_chart_visualization_refresh_pending=false;
int g_chart_visualization_refresh_passes=0;
ulong g_chart_visualization_epoch=1;
bool g_diag_recovery_gate_initialized=false;
bool g_diag_last_recovery_gate=false;
bool g_first_local_rebuild=false;
long g_last_reconcile_slot=-1;
ulong g_reconcile_entities[256];
int g_reconcile_checks[256];
int g_reconcile_count=0;

#define AB_ORDER_SELECTION_CLICK_GUARD_MS 350
#define AB_PANEL_CLICK_GUARD_MS 350

void FingerprintMix(ulong &value,const ulong item);
AB_PanelPositionView BuildPanelPositionView(void);
AB_PanelHeaderView BuildPanelHeaderView(void);
AB_PanelBasketView BuildPanelBasketView(void);
void BuildPanelLogView(AB_PanelLogView &view);
ulong PanelPositionDisplayFingerprint(const AB_PanelPositionView &view);
ulong PanelHeaderDisplayFingerprint(const AB_PanelHeaderView &view);
ulong PanelBasketDisplayFingerprint(const AB_PanelBasketView &view);
ulong PanelLogDisplayFingerprint(const AB_PanelLogView &view);
bool FlushPendingChartVisualizationPasses(void);
ulong BuildChartVisualizationFingerprint(void);
void RequestChartVisualizationRefresh(void);
void RequestChartVisualizationDelayedPasses(const int passes);

void RequestUiRefresh(const uint flags)
  {
   g_ui_refresh.Mark(flags);
  }

void FlushUiRefresh(void)
  {
   if(!g_ui_initialized)
      return;
   if(!g_ui_refresh.BeginFlush())
      return;

   // Build all read-only display views before comparing any layer fingerprint.
   AB_PanelPositionView position=BuildPanelPositionView();
   AB_PanelHeaderView header=BuildPanelHeaderView();
   AB_PanelBasketView basket=BuildPanelBasketView();
   AB_PanelLogView log;
   BuildPanelLogView(log);
   bool redraw_required=false;
   uint dynamic_upload_flags=AB_UI_DIRTY_NONE;
   g_dynamic_layers.SetOrigin(g_panel.CanvasX(),g_panel.CanvasY());
   if(g_ui_refresh.Needs(AB_UI_DIRTY_STATIC) ||
      g_ui_refresh.Needs(AB_UI_DIRTY_LAYOUT))
     {
      g_panel.RefreshStatic();
      g_dynamic_layers.SetPage(g_panel.Tab(),g_panel.IsCollapsed());
      g_dynamic_layers.Move();
      g_ui_refresh.Clear(AB_UI_DIRTY_STATIC);
      g_ui_refresh.Clear(AB_UI_DIRTY_LAYOUT);
      redraw_required=true;
     }

   if(g_ui_refresh.Needs(AB_UI_DIRTY_HEADER))
     {
      ulong fingerprint=PanelHeaderDisplayFingerprint(header);
      bool changed=g_ui_refresh.FingerprintChanged(AB_UI_DIRTY_HEADER,fingerprint);
      g_ui_refresh.Clear(AB_UI_DIRTY_HEADER);
      if(changed)
        {
         g_dynamic_layers.DrawHeader(header);
         dynamic_upload_flags|=AB_UI_DIRTY_HEADER;
        }
     }
   if(g_ui_refresh.Needs(AB_UI_DIRTY_ORDER))
     {
      ulong fingerprint=PanelPositionDisplayFingerprint(position);
      bool changed=g_ui_refresh.FingerprintChanged(AB_UI_DIRTY_ORDER,fingerprint);
      g_ui_refresh.Clear(AB_UI_DIRTY_ORDER);
      if(changed)
        {
         g_dynamic_layers.DrawOrder(position);
         dynamic_upload_flags|=AB_UI_DIRTY_ORDER;
        }
     }
   if(g_ui_refresh.Needs(AB_UI_DIRTY_BASKET))
     {
      ulong fingerprint=PanelBasketDisplayFingerprint(basket);
      bool changed=g_ui_refresh.FingerprintChanged(AB_UI_DIRTY_BASKET,fingerprint);
      g_ui_refresh.Clear(AB_UI_DIRTY_BASKET);
      if(changed)
        {
         g_dynamic_layers.DrawBasket(basket);
         dynamic_upload_flags|=AB_UI_DIRTY_BASKET;
        }
     }
   if(g_ui_refresh.Needs(AB_UI_DIRTY_LOG))
     {
      ulong fingerprint=PanelLogDisplayFingerprint(log);
      bool changed=g_ui_refresh.FingerprintChanged(AB_UI_DIRTY_LOG,fingerprint);
      g_ui_refresh.Clear(AB_UI_DIRTY_LOG);
      if(changed)
        {
         g_dynamic_layers.DrawLog(log);
         dynamic_upload_flags|=AB_UI_DIRTY_LOG;
        }
     }
   FlushPendingChartVisualizationPasses();
   if(g_ui_refresh.Needs(AB_UI_DIRTY_CHART))
     {
      ulong fingerprint=BuildChartVisualizationFingerprint();
      bool changed=g_ui_refresh.FingerprintChanged(AB_UI_DIRTY_CHART,fingerprint);
      g_ui_refresh.Clear(AB_UI_DIRTY_CHART);
      if(changed)
        {
         RefreshChartVisualization();
         redraw_required=true;
        }
     }

   if(dynamic_upload_flags!=AB_UI_DIRTY_NONE)
     {
      g_dynamic_layers.UploadDirty(dynamic_upload_flags);
      redraw_required=true;
     }
   if(redraw_required)
      ChartRedraw();
   g_ui_refresh.EndFlush();
  }

AB_BASKET_EXIT_MODE ResolveBasketExitMode(void)
  {
   if(g_runtime_basket_mode==BASKET_EXIT_TRAILING)
      return AB_BASKET_EXIT_TRAILING;
   if(g_runtime_basket_mode==BASKET_EXIT_ONE_SHOT_SL)
      return AB_BASKET_EXIT_ONE_SHOT_SL;
   return AB_BASKET_EXIT_TP;
  }

AB_CanvasPanelConfig BuildPanelConfig(void)
  {
   AB_CanvasPanelConfig config;
   config.anchor=Panel_Default_Anchor;
   config.panel_x=g_runtime_panel_x;
   config.panel_y=g_runtime_panel_y;
   config.panel_width=Panel_Default_Width;
   config.panel_height=Panel_Default_Height;
   config.page_vertical_spacing=Panel_Page_Vertical_Spacing;
   config.function_button_height=Panel_Function_Button_Height;
   config.tp_label_font_size=g_runtime_tp_label_font_size;
   config.log_history=g_runtime_log_history;
   config.red_green_mode=Panel_Red_Green_Mode;
   config.tp_line_display_mode=TP_Line_Display_Mode;
   config.trail_1=g_runtime_trail[0];
   config.trail_2=g_runtime_trail[1];
   config.trail_3=g_runtime_trail[2];
   config.trail_4=g_runtime_trail[3];
   config.close_1=g_runtime_close_ratio[0];
   config.close_2=g_runtime_close_ratio[1];
   config.close_3=g_runtime_close_ratio[2];
   config.close_4=g_runtime_close_ratio[3];
   config.basket_mode=(int)g_runtime_basket_mode;
   config.basket_trailing=g_runtime_basket_trailing;
   config.basket_reverse_close=g_runtime_basket_reverse_close;
   config.auto_mode=g_runtime_auto_mode;
   config.ladder_enabled=g_runtime_ladder_enabled;
   return config;
  }

void ClearSelectedPosition(void)
  {
   ulong previous_ticket=g_selected_ticket;
   g_selected_ticket=0;
   g_selected_position_identifier=0;
   g_selected_breakout=false;
   if(previous_ticket!=0)
     {
      g_panel_log.Add(TimeCurrent(),"已取消订单选择 #"+
                      IntegerToString((long)previous_ticket)+"。");
      RequestUiRefresh(AB_UI_DIRTY_LOG);
     }
  }

bool RefreshSelectedPositionSnapshot(void)
  {
   if(g_selected_ticket==0)
      return false;
   if(!PositionSelectByTicket(g_selected_ticket))
     {
      ClearSelectedPosition();
      return false;
     }
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
     {
      ClearSelectedPosition();
      return false;
     }
   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
     {
      ClearSelectedPosition();
      return false;
     }
   g_selected_position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   AB_BreakoutLineage breakout_lineage;
   g_selected_breakout=(long)PositionGetInteger(POSITION_MAGIC)==Straddle_Magic ||
                       g_breakout_registry.GetByTicket(g_selected_ticket,breakout_lineage);
   return true;
  }

bool SelectChartPosition(const ulong ticket)
  {
   if(ticket==0)
      return false;
   if(g_selected_ticket==ticket)
     {
      ClearSelectedPosition();
      return true;
     }
   if(!PositionSelectByTicket(ticket))
      return false;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return false;
   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
      return false;
   g_selected_ticket=ticket;
   g_selected_position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   AB_BreakoutLineage breakout_lineage;
   g_selected_breakout=(long)PositionGetInteger(POSITION_MAGIC)==Straddle_Magic ||
                       g_breakout_registry.GetByTicket(ticket,breakout_lineage);
   if(!RefreshSelectedPositionSnapshot())
      return false;
   g_panel_log.Add(TimeCurrent(),"已选择订单 #"+IntegerToString((long)ticket)+"。");
   RequestUiRefresh(AB_UI_DIRTY_LOG);
   return true;
  }

void MarkOrderSelectionObjectClick(void)
  {
   g_last_order_selection_click_ms=GetTickCount();
  }

void MarkPanelObjectClick(void)
  {
   g_last_panel_object_click_ms=GetTickCount();
  }

bool ShouldIgnoreChartClickAfterOrderObjectClick(void)
  {
   if(g_last_order_selection_click_ms==0)
      return false;
   uint now=GetTickCount();
   uint elapsed=now-g_last_order_selection_click_ms;
   g_last_order_selection_click_ms=0;
   return elapsed<=AB_ORDER_SELECTION_CLICK_GUARD_MS;
  }

bool ShouldIgnoreChartClickAfterPanelObjectClick(void)
  {
   if(g_last_panel_object_click_ms==0)
      return false;
   uint now=GetTickCount();
   uint elapsed=now-g_last_panel_object_click_ms;
   g_last_panel_object_click_ms=0;
   return elapsed<=AB_PANEL_CLICK_GUARD_MS;
  }

void FillPanelPositionView(AB_PanelPositionView &view,
                           const ulong ticket,
                           const AB_ManagedEntityId &entity_id,
                           const bool managed,
                           const bool selected,
                           const bool breakout,
                           const string alias)
  {
   view.has_position=true;
   view.ticket=ticket;
   view.entity_id=entity_id;
   view.managed=managed;
   view.selected=selected;
   view.breakout=breakout;
   view.alias=alias;
   if(PositionSelectByTicket(ticket))
     {
      view.is_buy=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      view.volume=PositionGetDouble(POSITION_VOLUME);
      view.open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      view.profit=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
  }

string NormalAliasByEntity(const AB_ManagedEntityId &entity_id)
  {
   int display_number=0;
   for(int i=0;i<g_position_registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!g_position_registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      display_number++;
      if(lineage.entity_id.value==entity_id.value)
         return "普"+IntegerToString(display_number);
     }
   return "";
  }

string BreakoutAliasByEntity(const AB_ManagedEntityId &entity_id)
  {
   int display_number=0;
   for(int i=0;i<g_breakout_registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      display_number++;
      if(lineage.entity_id.value==entity_id.value)
         return "突"+IntegerToString(display_number);
     }
   return "";
  }

AB_PanelPositionView BuildPanelPositionView()
  {
   AB_PanelPositionView view;
   view.has_position=false;
   view.is_buy=true;
   view.ticket=0;
   view.volume=0.0;
   view.open_price=0.0;
   view.profit=0.0;
   view.entity_id.value=0;
   view.managed=false;
   view.selected=false;
   view.breakout=false;
   view.alias="";

   if(RefreshSelectedPositionSnapshot())
     {
      AB_PositionLineage normal_lineage;
      if(!g_selected_breakout &&
         g_position_registry.GetByTicket(g_selected_ticket,normal_lineage))
        {
         FillPanelPositionView(view,g_selected_ticket,normal_lineage.entity_id,
                               normal_lineage.managed,true,false,
                               normal_lineage.managed ? NormalAliasByEntity(normal_lineage.entity_id) : "");
         return view;
        }
      AB_BreakoutLineage breakout_lineage;
      if(g_breakout_registry.GetByTicket(g_selected_ticket,breakout_lineage))
        {
         FillPanelPositionView(view,g_selected_ticket,breakout_lineage.entity_id,
                               breakout_lineage.managed,true,true,
                               breakout_lineage.managed ? BreakoutAliasByEntity(breakout_lineage.entity_id) : "");
         return view;
        }
      AB_ManagedEntityId empty_entity;
      empty_entity.value=0;
      FillPanelPositionView(view,g_selected_ticket,empty_entity,false,true,
                            g_selected_breakout,"");
      return view;
     }

   AB_PositionLineage latest_lineage;
   if(AB_FindLatestManagedNormalPosition(g_position_registry,_Symbol,latest_lineage))
     {
      FillPanelPositionView(view,latest_lineage.current_ticket,latest_lineage.entity_id,
                            true,false,false,
                            NormalAliasByEntity(latest_lineage.entity_id));
      return view;
     }

   int breakout_number=0;
   for(int i=0;i<g_breakout_registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      breakout_number++;
      FillPanelPositionView(view,lineage.current_ticket,lineage.entity_id,
                            true,false,true,"突"+IntegerToString(breakout_number));
      return view;
     }

   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)==Straddle_Magic)
         continue;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      AB_PositionLineage normal_lineage;
      if(g_position_registry.GetByPositionIdentifier(position_identifier,normal_lineage) &&
         normal_lineage.managed)
         continue;
      AB_ManagedEntityId empty_entity;
      empty_entity.value=0;
      FillPanelPositionView(view,ticket,empty_entity,false,false,false,"");
      return view;
     }
   return view;
  }

AB_PanelHeaderView BuildPanelHeaderView()
  {
   AB_PanelHeaderView header;
   header.managed_buy_count=0;
   header.managed_sell_count=0;
   header.breakout_count=0;
   header.unmanaged_count=0;

   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)==Straddle_Magic)
        {
         header.breakout_count++;
         continue;
        }

      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      AB_PositionLineage normal_lineage;
      if(g_position_registry.GetByPositionIdentifier(position_identifier,normal_lineage) &&
         normal_lineage.managed)
        {
         if(type==POSITION_TYPE_BUY)
            header.managed_buy_count++;
         else
            header.managed_sell_count++;
         continue;
        }
      header.unmanaged_count++;
     }
   return header;
  }

string BasketModeLabel(const AB_BASKET_EXIT_MODE mode)
  {
   if(mode==AB_BASKET_EXIT_TRAILING)
      return "追踪止损";
   if(mode==AB_BASKET_EXIT_ONE_SHOT_SL)
      return "单次保本 SL";
   return "保本 TP";
  }

string BasketPhaseLabel(const AB_BASKET_PHASE phase)
  {
   if(phase==AB_BASKET_ACTIVE)
      return "运行";
   if(phase==AB_BASKET_EXITING)
      return "退出中";
   if(phase==AB_BASKET_CANCELLING)
      return "取消中";
   if(phase==AB_BASKET_SWITCHING)
      return "切换中";
   if(phase==AB_BASKET_FORCE_CLOSING)
      return "强平中";
   return "未启用";
  }

void FillPanelBasketSideView(AB_PanelBasketSideView &view,
                             const AB_BasketSnapshot &snapshot,
                             const MqlTick &tick,
                             const bool has_tick)
  {
   view.enabled=snapshot.phase!=AB_BASKET_NONE && snapshot.symbol==_Symbol;
   view.mode_label=view.enabled
      ? BasketModeLabel(snapshot.exit_mode)+(snapshot.no_ladder ? " · 无阶梯" : "")
      : "";
   view.phase_label=view.enabled ? BasketPhaseLabel(snapshot.phase) : "";
   view.active_members=0;
   view.total_members=view.enabled ? snapshot.member_count : 0;
   view.has_trigger_price=false;
   view.trigger_price=0.0;
   view.has_zero_price=view.enabled && snapshot.zero_price>0.0;
   view.zero_price=view.has_zero_price ? snapshot.zero_price : 0.0;
   view.live_profit=0.0;
   if(!view.enabled)
      return;

   bool usable_tick=has_tick && tick.bid>0.0 && tick.ask>0.0;
   if(snapshot.exit_mode==AB_BASKET_EXIT_TRAILING && usable_tick &&
      snapshot.favorable_extreme>0.0)
     {
      double distance=AB_MicroPointDistance(g_symbol_rules,g_runtime_basket_trailing);
      view.trigger_price=snapshot.direction==POSITION_TYPE_BUY
         ? snapshot.favorable_extreme-distance
         : snapshot.favorable_extreme+distance;
      view.has_trigger_price=view.trigger_price>0.0;
     }
   else if(view.has_zero_price)
     {
      view.trigger_price=view.zero_price;
      view.has_trigger_price=true;
     }

   for(int i=0;i<snapshot.member_count;i++)
     {
      if(!snapshot.members[i].active)
         continue;
      ulong ticket=AB_FindPositionTicketByIdentifier(snapshot.members[i].position_identifier);
      if(ticket==0 || !PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      view.active_members++;
      view.live_profit+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
  }

AB_PanelBasketView BuildPanelBasketView()
  {
   AB_PanelBasketView view;
   MqlTick tick;
   ZeroMemory(tick);
   bool has_tick=SymbolInfoTick(_Symbol,tick);
   FillPanelBasketSideView(view.long_side,g_basket_long,tick,has_tick);
   FillPanelBasketSideView(view.short_side,g_basket_short,tick,has_tick);
   view.active_members=view.long_side.active_members+view.short_side.active_members;
   view.has_live_profit=view.active_members>0;
   view.live_profit=view.long_side.live_profit+view.short_side.live_profit;
   return view;
  }

void BuildPanelLogView(AB_PanelLogView &view)
  {
   g_panel_log.BuildView(view);
  }

bool LatestManagedEntity(AB_ManagedEntityId &entity_id)
  {
   entity_id.value=0;
   AB_PositionLineage latest;
   if(!AB_FindLatestManagedNormalPosition(g_position_registry,_Symbol,latest))
      return false;
   entity_id=latest.entity_id;
   return entity_id.value!=0;
  }

bool SelectedNormalEntity(AB_ManagedEntityId &entity_id)
  {
   entity_id.value=0;
   if(!RefreshSelectedPositionSnapshot() || g_selected_breakout)
      return false;
   AB_PositionLineage lineage;
   if(!g_position_registry.GetByTicket(g_selected_ticket,lineage) || !lineage.managed)
      return false;
   entity_id=lineage.entity_id;
   return entity_id.value!=0;
  }

bool ResolveNormalEntityForAction(AB_ManagedEntityId &entity_id)
  {
   entity_id.value=0;
   if(g_selected_ticket!=0)
      return SelectedNormalEntity(entity_id);
   return LatestManagedEntity(entity_id);
  }

void RefreshChartVisualization(void)
  {
   AB_RefreshChartVisualization(g_position_registry,g_ladder_book,
      g_breakout_registry,g_breakout_ladder_book,g_ladder_config,
      g_basket_long,g_basket_short,
      g_symbol_rules,_Symbol,Straddle_Magic,TP_Line_Display_Mode,
      g_runtime_tp_label_font_size,g_selected_ticket);
  }

void RequestChartVisualizationRefresh(void)
  {
   RequestUiRefresh(AB_UI_DIRTY_CHART);
  }

void RequestChartVisualizationDelayedPasses(const int passes)
  {
   g_chart_visualization_refresh_pending=true;
   if(g_chart_visualization_refresh_passes<passes)
      g_chart_visualization_refresh_passes=passes;
  }

bool FlushPendingChartVisualizationPasses(void)
  {
   if(!g_chart_visualization_refresh_pending ||
      g_chart_visualization_refresh_passes<=0)
     {
      g_chart_visualization_refresh_passes=0;
      g_chart_visualization_refresh_pending=false;
      return false;
     }
   g_chart_visualization_epoch++;
   RequestChartVisualizationRefresh();
   g_chart_visualization_refresh_passes--;
   if(g_chart_visualization_refresh_passes<=0)
     {
      g_chart_visualization_refresh_passes=0;
      g_chart_visualization_refresh_pending=false;
     }
   return true;
  }

string PanelActionLogLabel(const AB_PANEL_ACTION action)
  {
   if(action==AB_PANEL_ACTION_JOIN_MANAGEMENT) return "加入管理";
   if(action==AB_PANEL_ACTION_EXIT_MANAGEMENT) return "退出管理";
   if(action==AB_PANEL_ACTION_BASKET_LONG) return "多单组合";
   if(action==AB_PANEL_ACTION_BASKET_SHORT) return "空单组合";
   if(action==AB_PANEL_ACTION_BASKET_LONG_NO_LADDER) return "多单无阶梯组合";
   if(action==AB_PANEL_ACTION_BASKET_SHORT_NO_LADDER) return "空单无阶梯组合";
   if(action==AB_PANEL_ACTION_BASKET_CANCEL) return "取消组合";
   if(action==AB_PANEL_ACTION_STRADDLE_START) return "启动突破";
   if(action==AB_PANEL_ACTION_STRADDLE_CANCEL) return "取消挂单";
   if(action==AB_PANEL_ACTION_STRADDLE_SETTLE) return "立即结算";
   if(action==AB_PANEL_ACTION_CLOSE_ALL) return "全部平仓";
   if(action==AB_PANEL_ACTION_TRIGGER_NEXT_LEVEL) return "触发下一阶";
   if(action==AB_PANEL_ACTION_STOP_TRAILING) return "停止追踪";
   if(action>=AB_PANEL_ACTION_TRAIL_1 && action<=AB_PANEL_ACTION_TRAIL_4)
      return "追踪止损";
   if(action>=AB_PANEL_ACTION_CLOSE_5 && action<=AB_PANEL_ACTION_CLOSE_50)
      return "手动平仓";
   return "面板操作";
  }

string DiagnosticErrorLabel(const AB_ERROR_CODE error)
  {
   if(error==AB_ERROR_NONE) return "无";
   if(error==AB_ERROR_INVALID_ARGUMENT) return "参数或目标无效";
   if(error==AB_ERROR_INVALID_SYMBOL_RULE) return "品种规则无效";
   if(error==AB_ERROR_VOLUME_TOO_SMALL) return "手数不足";
   if(error==AB_ERROR_INVALID_REMAINDER) return "剩余手数无效";
   if(error==AB_ERROR_TEMPORARY_RESTRICTION) return "恢复保护锁定";
   if(error==AB_ERROR_REQUEST_UNKNOWN) return "请求结果未知";
   if(error==AB_ERROR_NOT_MANAGED) return "订单未纳入管理";
   if(error==AB_ERROR_CONFLICT) return "同一订单已有操作处理中";
   return "未知错误";
  }

void PrintRecoveryDiagnostic(const string stage)
  {
   bool history_check=g_persistence.RecoveryRequiresHistoryCheck();
   bool unknown_request=g_persistence.HasUnknownRequest();
   bool can_issue=g_persistence.CanIssueNewActions();
   PrintFormat("AB_DIAG recovery stage=%s can_issue=%s recovery_check=%s unknown_request=%s committed=%s sequence=%s",
      stage,can_issue ? "true" : "false",history_check ? "true" : "false",
      unknown_request ? "true" : "false",
      g_persistence.HasCommittedState() ? "true" : "false",
      IntegerToString((long)g_persistence.Sequence()));
  }

void ExecutePanelAction(const AB_PANEL_ACTION action)
  {
   if(action==AB_PANEL_ACTION_NONE)
      return;
   if(action==AB_PANEL_ACTION_BASKET_MODE_TP ||
      action==AB_PANEL_ACTION_BASKET_MODE_TRAILING ||
      action==AB_PANEL_ACTION_BASKET_MODE_ONE_SHOT_SL)
     {
      g_runtime_basket_mode=action==AB_PANEL_ACTION_BASKET_MODE_TP ? BASKET_EXIT_TP :
                            action==AB_PANEL_ACTION_BASKET_MODE_TRAILING ? BASKET_EXIT_TRAILING :
                            BASKET_EXIT_ONE_SHOT_SL;
      g_panel.Configure(BuildPanelConfig());
      g_panel_log.Add(TimeCurrent(),"组合保本模式已切换为 "+
                      BasketModeLabel(ResolveBasketExitMode())+"。");
      PersistRuntimeIfChanged(true);
      RequestUiRefresh(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_BASKET|AB_UI_DIRTY_LOG);
      return;
     }
   if(action==AB_PANEL_ACTION_AUTO_MODE_M1 ||
      action==AB_PANEL_ACTION_AUTO_MODE_ENTRY ||
      action==AB_PANEL_ACTION_AUTO_MODE_OFF)
     {
      g_runtime_auto_mode=action==AB_PANEL_ACTION_AUTO_MODE_M1 ? 0 :
                          action==AB_PANEL_ACTION_AUTO_MODE_ENTRY ? 1 : 2;
      g_auto_sl_trigger_latches.Reset();
      g_auto_sl_tick_cursor_msc=0;
      g_panel.Configure(BuildPanelConfig());
      g_panel_log.Add(TimeCurrent(),"自动保本模式已切换为 "+
                      (g_runtime_auto_mode==0 ? "M1极值止损" :
                       g_runtime_auto_mode==1 ? "开仓价止损" : "关闭")+"。");
      RequestUiRefresh(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_LOG);
      return;
     }
   if(action==AB_PANEL_ACTION_TOGGLE_LADDER)
     {
      g_runtime_ladder_enabled=!g_runtime_ladder_enabled;
      g_panel.Configure(BuildPanelConfig());
      g_panel_log.Add(TimeCurrent(),"阶梯止盈已"+(g_runtime_ladder_enabled ? "开启" : "关闭")+"。");
      RequestUiRefresh(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_LOG);
      return;
     }
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return;
   AB_CommandRequest command;
   command.command=AB_COMMAND_NONE;
   command.entity_id.value=0;
   command.sl_mode=AB_SL_NONE;
   command.ratio_percent=0.0;
   command.distance_micro_points=0;
   command.position_ticket=0;
   bool clear_selection_on_accept=false;
   if(action==AB_PANEL_ACTION_JOIN_MANAGEMENT)
     {
      if(!RefreshSelectedPositionSnapshot() || g_selected_breakout)
         return;
      AB_PositionLineage lineage;
      if(g_position_registry.GetByTicket(g_selected_ticket,lineage) && lineage.managed)
         return;
      command.command=AB_COMMAND_JOIN;
      command.position_ticket=g_selected_ticket;
      clear_selection_on_accept=true;
     }
   else if(action==AB_PANEL_ACTION_EXIT_MANAGEMENT)
     {
      if(!SelectedNormalEntity(command.entity_id))
         return;
      command.command=AB_COMMAND_EXIT_MANAGEMENT;
      clear_selection_on_accept=true;
     }
   else if(action==AB_PANEL_ACTION_CLOSE_ALL)
      {
       if(!ResolveNormalEntityForAction(command.entity_id))
          return;
       command.command=AB_COMMAND_EXIT;
       command.ratio_percent=100.0;
      }
   else if(action==AB_PANEL_ACTION_TRIGGER_NEXT_LEVEL)
      {
       if(!ResolveNormalEntityForAction(command.entity_id))
          return;
       command.command=AB_COMMAND_TRIGGER_NEXT_LEVEL;
      }
   else if(action==AB_PANEL_ACTION_SL_M1 || action==AB_PANEL_ACTION_SL_ENTRY ||
           action==AB_PANEL_ACTION_TRAIL_1 || action==AB_PANEL_ACTION_TRAIL_2 ||
           action==AB_PANEL_ACTION_TRAIL_3 || action==AB_PANEL_ACTION_TRAIL_4 ||
           action==AB_PANEL_ACTION_STOP_TRAILING ||
           action==AB_PANEL_ACTION_CLOSE_5 || action==AB_PANEL_ACTION_CLOSE_10 ||
           action==AB_PANEL_ACTION_CLOSE_25 || action==AB_PANEL_ACTION_CLOSE_50)
     {
      if(!ResolveNormalEntityForAction(command.entity_id))
         return;
      if(action==AB_PANEL_ACTION_SL_M1)
        {
         command.command=AB_COMMAND_SELECT_SL_MODE;
         command.sl_mode=AB_SL_M1;
         command.distance_micro_points=Button_M1_Offset_MicroPoints;
        }
      else if(action==AB_PANEL_ACTION_SL_ENTRY)
        {
         command.command=AB_COMMAND_SELECT_SL_MODE;
         command.sl_mode=AB_SL_ENTRY;
         command.distance_micro_points=Button_Entry_Offset_MicroPoints;
        }
      else if(action==AB_PANEL_ACTION_TRAIL_1 || action==AB_PANEL_ACTION_TRAIL_2 ||
              action==AB_PANEL_ACTION_TRAIL_3 || action==AB_PANEL_ACTION_TRAIL_4)
        {
         command.command=AB_COMMAND_SELECT_SL_MODE;
         command.sl_mode=action==AB_PANEL_ACTION_TRAIL_1 ? AB_SL_TRAILING_1 :
                         action==AB_PANEL_ACTION_TRAIL_2 ? AB_SL_TRAILING_2 :
                         action==AB_PANEL_ACTION_TRAIL_3 ? AB_SL_TRAILING_3 : AB_SL_TRAILING_4;
         command.distance_micro_points=action==AB_PANEL_ACTION_TRAIL_1 ? g_runtime_trail[0] :
                                        action==AB_PANEL_ACTION_TRAIL_2 ? g_runtime_trail[1] :
                                        action==AB_PANEL_ACTION_TRAIL_3 ? g_runtime_trail[2] : g_runtime_trail[3];
        }
      else if(action==AB_PANEL_ACTION_STOP_TRAILING)
         command.command=AB_COMMAND_STOP_TRAILING;
      else
        {
         command.command=AB_COMMAND_MANUAL_CLOSE;
         command.ratio_percent=action==AB_PANEL_ACTION_CLOSE_5 ? g_runtime_close_ratio[0] :
                               action==AB_PANEL_ACTION_CLOSE_10 ? g_runtime_close_ratio[1] :
                               action==AB_PANEL_ACTION_CLOSE_25 ? g_runtime_close_ratio[2] : g_runtime_close_ratio[3];
        }
     }
   else if(action==AB_PANEL_ACTION_BASKET_LONG)
      command.command=AB_COMMAND_BASKET_LONG;
   else if(action==AB_PANEL_ACTION_BASKET_SHORT)
      command.command=AB_COMMAND_BASKET_SHORT;
   else if(action==AB_PANEL_ACTION_BASKET_LONG_NO_LADDER)
      command.command=AB_COMMAND_BASKET_LONG_NO_LADDER;
   else if(action==AB_PANEL_ACTION_BASKET_SHORT_NO_LADDER)
      command.command=AB_COMMAND_BASKET_SHORT_NO_LADDER;
   else if(action==AB_PANEL_ACTION_BASKET_CANCEL)
      command.command=AB_COMMAND_BASKET_CANCEL;
   else if(action==AB_PANEL_ACTION_STRADDLE_START)
     {
      AB_ReconcileStraddleLifecycleV32_12(g_straddle_state,g_operation_ledger,
         _Symbol,Straddle_Magic);
      command.command=AB_COMMAND_STRADDLE_START;
      command.entity_id=g_straddle_state.entity_id;
      if(command.entity_id.value==0)
         command.entity_id.value=(ulong)TimeCurrent();
     }
   else if(action==AB_PANEL_ACTION_STRADDLE_CANCEL)
      command.command=AB_COMMAND_STRADDLE_CANCEL_ORDERS;
   else if(action==AB_PANEL_ACTION_STRADDLE_SETTLE)
      command.command=AB_COMMAND_STRADDLE_SETTLE;
   if(command.command==AB_COMMAND_NONE)
      return;
   // Commands that trade are not started while AutoTrading is off.
   if(!AB_TradingAllowed() && command.command!=AB_COMMAND_JOIN &&
      command.command!=AB_COMMAND_EXIT_MANAGEMENT &&
      command.command!=AB_COMMAND_STOP_TRAILING &&
      command.command!=AB_COMMAND_BASKET_CANCEL)
     {
      g_panel_log.Add(TimeCurrent(),"自动交易未开启，"+PanelActionLogLabel(action)+"未执行。");
      RequestUiRefresh(AB_UI_DIRTY_LOG);
      return;
     }
   AB_CommandResponse response;
   if(command.command==AB_COMMAND_STRADDLE_START)
     {
      if(!g_persistence.CanIssueNewActions())
         response=AB_RejectCommand(AB_ERROR_TEMPORARY_RESTRICTION,g_engine_snapshot.state_version);
      else
         response=AB_StartStraddleV32_12(g_straddle_state,g_operation_ledger,
            g_symbol_rules,tick,command.entity_id,_Symbol,Straddle_Magic,
            Straddle_Lot_Size,Straddle_Distance_MicroPoints,
            Straddle_Initial_SL_MicroPoints,Slippage_MicroPoints,
            g_engine_snapshot.state_version);
     }
   else
      response=AB_ExecuteCommand(command,g_position_registry,g_breakout_registry,
         g_basket_long,g_basket_short,g_straddle_state,g_ladder_book,g_persistence,
         g_operation_ledger,g_symbol_rules,tick,_Symbol,Normal_Managed_Magic,
         Straddle_Magic,Straddle_Lot_Size,Straddle_Distance_MicroPoints,
         Straddle_Initial_SL_MicroPoints,Slippage_MicroPoints,g_ladder_config.normal,
         ResolveBasketExitMode(),g_engine_snapshot.state_version);
   string action_label=PanelActionLogLabel(action);
   PrintFormat("AB_DIAG command action=%s id=%d command=%d result=%d error=%d(%s) ticket=%s entity=%s can_issue=%s",
      action_label,(int)action,(int)command.command,(int)response.result,
      (int)response.error,DiagnosticErrorLabel(response.error),
      IntegerToString((long)command.position_ticket),
      IntegerToString((long)command.entity_id.value),
      g_persistence.CanIssueNewActions() ? "true" : "false");
   if(response.result==AB_COMMAND_ACCEPTED)
      g_panel_log.Add(TimeCurrent(),action_label+"命令已接受。");
   else if(response.result==AB_COMMAND_PENDING)
     {
      string pending_notice=action_label+"命令已提交/处理中";
      if(response.operation_id!=0)
         pending_notice+="，操作 ID "+IntegerToString((long)response.operation_id);
      g_panel_log.Add(TimeCurrent(),pending_notice+"。");
     }
   else if(response.result==AB_COMMAND_REJECTED)
      g_panel_log.Add(TimeCurrent(),action_label+"命令被拒绝，错误 "+
                      IntegerToString((int)response.error)+"（"+
                      DiagnosticErrorLabel(response.error)+"）。");
   RequestUiRefresh(AB_UI_DIRTY_LOG);
   if(response.result==AB_COMMAND_ACCEPTED && clear_selection_on_accept)
      ClearSelectedPosition();
    PersistRuntimeIfChanged(true);
  }

bool HandlePanelClickAt(const int chart_x,const int chart_y)
  {
   bool panel_hit=g_panel.ContainsPoint(chart_x,chart_y);
   AB_PANEL_ACTION action=g_panel.HandleClick(chart_x,chart_y);
   if(action==AB_PANEL_ACTION_CLEAR_LOG)
     {
      g_panel_log.Clear();
      RequestUiRefresh(AB_UI_DIRTY_LOG);
      return true;
     }
   if(action!=AB_PANEL_ACTION_NONE)
     {
      ExecutePanelAction(action);
      RequestUiRefresh(AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_BASKET|
                       AB_UI_DIRTY_LOG);
      RequestChartVisualizationRefresh();
      return true;
     }
   if(panel_hit)
     {
      RequestUiRefresh(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_LAYOUT|
                       AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_BASKET|
                       AB_UI_DIRTY_LOG);
      return true;
     }
   return false;
  }

void FingerprintMix(ulong &value,const ulong item)
  {
   value=(value^item)*1099511628211;
  }

void MixDisplayString(ulong &value,const string text)
  {
   FingerprintMix(value,(ulong)StringLen(text));
   for(int i=0;i<StringLen(text);i++)
      FingerprintMix(value,(ulong)StringGetCharacter(text,i));
  }

bool ChartManagedSellHasVisibleLadder(const AB_ManagedEntityId &entity_id,
                                      AB_LadderBook &book,
                                      const AB_LadderLevelInput &inputs[],
                                      const double original_volume,
                                      const double current_volume)
  {
   if(TP_Line_Display_Mode==TP_LINE_OFF)
      return false;
   AB_LadderPositionState state;
   if(!book.Get(entity_id,state))
     {
      ZeroMemory(state);
      state.entity_id=entity_id;
      state.original_volume=original_volume;
      state.current_volume=current_volume;
      AB_LoadLadderLevels(state.levels,inputs);
     }
   state.current_volume=current_volume;
   if(state.original_volume<=0.0)
      state.original_volume=current_volume;
   for(int level=0;level<10;level++)
     {
      if(!AB_IsLadderLevelEnabled(inputs[level]))
         continue;
      AB_LadderLevelState level_state=state.levels[level];
      if(!level_state.enabled)
        {
         level_state.enabled=true;
         level_state.distance_micro_points=inputs[level].distance_micro_points;
         level_state.ratio_percent=inputs[level].close_ratio_percent;
        }
      if(level_state.completed)
         continue;
      if(AB_ComputeLadderCloseVolume(state,level_state,g_symbol_rules)>0.0)
         return true;
     }
   return false;
  }

void AddManagedChartQuoteDependencies(const ulong ticket,
                                      const AB_ManagedEntityId &entity_id,
                                      const double original_volume,
                                      AB_LadderBook &book,
                                      const AB_LadderLevelInput &inputs[],
                                      bool &need_bid,
                                      bool &need_ask,
                                      bool &need_spread)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket) ||
      PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return;
   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(type==POSITION_TYPE_BUY)
      need_bid=true;
   else if(type==POSITION_TYPE_SELL)
     {
      need_ask=true;
      if(ChartManagedSellHasVisibleLadder(entity_id,book,inputs,original_volume,
                                          PositionGetDouble(POSITION_VOLUME)))
         need_spread=true;
     }
  }

void ChartVisualizationQuoteDependencies(bool &need_bid,
                                         bool &need_ask,
                                         bool &need_spread)
  {
   need_bid=false;
   need_ask=false;
   need_spread=false;
   for(int index=0;index<g_position_registry.Count();index++)
     {
      AB_PositionLineage lineage;
      if(!g_position_registry.GetAt(index,lineage) || !lineage.managed ||
         lineage.symbol!=_Symbol)
         continue;
      AddManagedChartQuoteDependencies(lineage.current_ticket,lineage.entity_id,
         lineage.original_volume,g_ladder_book,g_ladder_config.normal,
         need_bid,need_ask,need_spread);
     }
   for(int index=0;index<g_breakout_registry.Count();index++)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(index,lineage) || !lineage.managed ||
         lineage.symbol!=_Symbol)
         continue;
      AddManagedChartQuoteDependencies(lineage.current_ticket,lineage.entity_id,
         lineage.original_volume,g_breakout_ladder_book,g_ladder_config.breakout,
         need_bid,need_ask,need_spread);
     }
  }

void MixChartLadderPositionFingerprint(ulong &value,AB_LadderBook &book,
                                       const AB_ManagedEntityId &entity_id)
  {
   AB_LadderPositionState state;
   if(!book.Get(entity_id,state))
     {
      FingerprintMix(value,0);
      return;
     }
   FingerprintMix(value,1);
   FingerprintMix(value,state.entity_id.value);
   FingerprintMix(value,(ulong)MathRound(state.original_volume*1000000.0));
   FingerprintMix(value,(ulong)MathRound(state.current_volume*1000000.0));
   for(int level=0;level<10;level++)
     {
      FingerprintMix(value,state.levels[level].enabled?1:0);
      FingerprintMix(value,state.levels[level].completed?1:0);
      FingerprintMix(value,state.levels[level].pending_request?1:0);
      FingerprintMix(value,state.levels[level].pending_operation_id);
      FingerprintMix(value,(ulong)MathRound(state.levels[level].distance_micro_points*1000.0));
      FingerprintMix(value,(ulong)MathRound(state.levels[level].ratio_percent*1000.0));
     }
  }

ulong BuildChartVisualizationFingerprint(void)
  {
   ulong value=1469598103934665603;
   FingerprintMix(value,g_chart_visualization_epoch);
   FingerprintMix(value,g_selected_ticket);
   FingerprintMix(value,(ulong)TP_Line_Display_Mode);
   FingerprintMix(value,(ulong)g_runtime_tp_label_font_size);
   FingerprintMix(value,(ulong)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0));
   FingerprintMix(value,(ulong)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0));

   for(int level=0;level<10;level++)
     {
      FingerprintMix(value,(ulong)MathRound(g_ladder_config.normal[level].distance_micro_points*1000.0));
      FingerprintMix(value,(ulong)MathRound(g_ladder_config.normal[level].close_ratio_percent*1000.0));
      FingerprintMix(value,(ulong)MathRound(g_ladder_config.breakout[level].distance_micro_points*1000.0));
      FingerprintMix(value,(ulong)MathRound(g_ladder_config.breakout[level].close_ratio_percent*1000.0));
     }

   int visible_normal_count=0;
   for(int index=0;index<g_position_registry.Count();index++)
     {
      AB_PositionLineage lineage;
      if(!g_position_registry.GetAt(index,lineage) || !lineage.managed ||
         lineage.symbol!=_Symbol)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
         continue;
      visible_normal_count++;
      FingerprintMix(value,lineage.entity_id.value);
      FingerprintMix(value,lineage.position_identifier);
      FingerprintMix(value,lineage.current_ticket);
      FingerprintMix(value,(ulong)MathRound(lineage.original_volume*1000000.0));
      FingerprintMix(value,(ulong)type);
      FingerprintMix(value,(ulong)MathRound(PositionGetDouble(POSITION_PRICE_OPEN)*100000000.0));
      FingerprintMix(value,(ulong)MathRound(PositionGetDouble(POSITION_VOLUME)*1000000.0));
      MixChartLadderPositionFingerprint(value,g_ladder_book,lineage.entity_id);
     }
   FingerprintMix(value,(ulong)visible_normal_count);

   int visible_breakout_count=0;
   for(int index=0;index<g_breakout_registry.Count();index++)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(index,lineage) || !lineage.managed ||
         lineage.symbol!=_Symbol)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type!=POSITION_TYPE_BUY && type!=POSITION_TYPE_SELL)
         continue;
      visible_breakout_count++;
      FingerprintMix(value,lineage.entity_id.value);
      FingerprintMix(value,lineage.position_identifier);
      FingerprintMix(value,lineage.current_ticket);
      FingerprintMix(value,(ulong)MathRound(lineage.original_volume*1000000.0));
      FingerprintMix(value,(ulong)type);
      FingerprintMix(value,(ulong)MathRound(PositionGetDouble(POSITION_PRICE_OPEN)*100000000.0));
      FingerprintMix(value,(ulong)MathRound(PositionGetDouble(POSITION_VOLUME)*1000000.0));
      MixChartLadderPositionFingerprint(value,g_breakout_ladder_book,lineage.entity_id);
     }
   FingerprintMix(value,(ulong)visible_breakout_count);

   int current_symbol_position_count=0;
   for(int index=0;index<PositionsTotal();index++)
     {
      ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !PositionSelectByTicket(ticket) ||
         PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      current_symbol_position_count++;
      FingerprintMix(value,ticket);
      FingerprintMix(value,(ulong)PositionGetInteger(POSITION_IDENTIFIER));
      FingerprintMix(value,(ulong)PositionGetInteger(POSITION_TYPE));
      FingerprintMix(value,(ulong)PositionGetInteger(POSITION_MAGIC));
      FingerprintMix(value,(ulong)MathRound(PositionGetDouble(POSITION_PRICE_OPEN)*100000000.0));
     }
   FingerprintMix(value,(ulong)current_symbol_position_count);

   bool need_bid=false;
   bool need_ask=false;
   bool need_spread=false;
   ChartVisualizationQuoteDependencies(need_bid,need_ask,need_spread);
   if(need_bid || need_ask || need_spread)
     {
      MqlTick tick;
      if(SymbolInfoTick(_Symbol,tick))
        {
         if(need_bid)
            FingerprintMix(value,(ulong)MathRound(tick.bid*100000000.0));
         if(need_ask)
            FingerprintMix(value,(ulong)MathRound(tick.ask*100000000.0));
         if(need_spread)
            FingerprintMix(value,(ulong)MathRound((tick.ask-tick.bid)*100000000.0));
        }
     }
   return value;
  }

ulong PanelPositionDisplayFingerprint(const AB_PanelPositionView &view)
  {
   ulong value=1469598103934665603;
   FingerprintMix(value,view.has_position?1:0);
   FingerprintMix(value,view.is_buy?1:0);
   FingerprintMix(value,view.ticket);
   FingerprintMix(value,(ulong)MathRound(view.volume*1000000.0));
   FingerprintMix(value,(ulong)MathRound(view.open_price*1000000.0));
   FingerprintMix(value,(ulong)(long)MathRound(view.profit*100.0));
   FingerprintMix(value,view.managed?1:0);
   FingerprintMix(value,view.selected?1:0);
   FingerprintMix(value,view.breakout?1:0);
   MixDisplayString(value,view.alias);
   return value;
  }

ulong PanelHeaderDisplayFingerprint(const AB_PanelHeaderView &view)
  {
   ulong value=1469598103934665603;
   FingerprintMix(value,(ulong)view.managed_buy_count);
   FingerprintMix(value,(ulong)view.managed_sell_count);
   FingerprintMix(value,(ulong)view.breakout_count);
   FingerprintMix(value,(ulong)view.unmanaged_count);
   return value;
  }

void MixBasketSideDisplayFingerprint(ulong &value,
                                     const AB_PanelBasketSideView &view)
  {
   FingerprintMix(value,view.enabled?1:0);
   MixDisplayString(value,view.mode_label);
   MixDisplayString(value,view.phase_label);
   FingerprintMix(value,(ulong)view.active_members);
   FingerprintMix(value,(ulong)view.total_members);
   FingerprintMix(value,view.has_trigger_price?1:0);
   FingerprintMix(value,(ulong)MathRound(view.trigger_price*1000000.0));
   FingerprintMix(value,view.has_zero_price?1:0);
   FingerprintMix(value,(ulong)MathRound(view.zero_price*1000000.0));
   FingerprintMix(value,(ulong)(long)MathRound(view.live_profit*100.0));
  }

ulong PanelBasketDisplayFingerprint(const AB_PanelBasketView &view)
  {
   ulong value=1469598103934665603;
   MixBasketSideDisplayFingerprint(value,view.long_side);
   MixBasketSideDisplayFingerprint(value,view.short_side);
   FingerprintMix(value,(ulong)view.active_members);
   FingerprintMix(value,view.has_live_profit?1:0);
   FingerprintMix(value,(ulong)(long)MathRound(view.live_profit*100.0));
   return value;
  }

ulong PanelLogDisplayFingerprint(const AB_PanelLogView &view)
  {
   return g_panel_log.Fingerprint();
  }

ulong RuntimeStateFingerprint()
  {
   ulong value=1469598103934665603;
   FingerprintMix(value,(ulong)g_position_registry.Count());
   for(int i=0;i<g_position_registry.Count();i++)
     {
      AB_PositionLineage item;
      if(g_position_registry.GetAt(i,item))
        {
         FingerprintMix(value,item.entity_id.value);
         FingerprintMix(value,item.position_identifier);
         FingerprintMix(value,(ulong)item.sl_mode);
         FingerprintMix(value,item.pending_operation_id);
         FingerprintMix(value,item.auto_sl_done?1:0);
        }
     }
   AB_LadderPositionState ladder;
   for(int book=0;book<2;book++)
     {
      int count=book==0 ? g_ladder_book.Count() : g_breakout_ladder_book.Count();
      FingerprintMix(value,(ulong)count);
      for(int i=0;i<count;i++)
        {
         bool found=book==0 ? g_ladder_book.GetAt(i,ladder)
                            : g_breakout_ladder_book.GetAt(i,ladder);
         if(!found) continue;
         FingerprintMix(value,ladder.entity_id.value);
         for(int level=0;level<10;level++)
           {
            FingerprintMix(value,ladder.levels[level].completed?1:0);
            FingerprintMix(value,ladder.levels[level].pending_operation_id);
           }
        }
     }
   FingerprintMix(value,(ulong)g_operation_ledger.Count());
   for(int i=0;i<g_operation_ledger.Count();i++)
     {
      AB_OperationRecord item;
      if(g_operation_ledger.GetAt(i,item))
        {
         FingerprintMix(value,item.operation_id);
         FingerprintMix(value,item.request_id);
         FingerprintMix(value,(ulong)item.state);
         FingerprintMix(value,(ulong)MathRound(item.completed_volume*1000000.0));
        }
     }
   FingerprintMix(value,(ulong)g_basket_long.phase);
   FingerprintMix(value,(ulong)MathRound(g_basket_long.favorable_extreme*1000000.0));
   FingerprintMix(value,(ulong)g_basket_short.phase);
   FingerprintMix(value,(ulong)MathRound(g_basket_short.favorable_extreme*1000000.0));
   FingerprintMix(value,(ulong)g_straddle_state.phase);
   FingerprintMix(value,g_straddle_state.buy_order_ticket);
   FingerprintMix(value,g_straddle_state.sell_order_ticket);
   FingerprintMix(value,g_straddle_state.rollback_operation_id);
   return value;
  }

void PersistRuntimeManifest()
  {
   g_persistence.SetRuntimeManifest(g_position_registry.Count(),
      g_breakout_registry.Count(),g_ladder_book.Count(),
      g_breakout_ladder_book.Count(),(int)g_basket_long.phase,
      (int)g_basket_short.phase,(int)g_straddle_state.phase,
      g_operation_ledger.Count());
  }

bool PersistObjectSnapshot()
  {
   ulong sequence=g_persistence.Sequence();
   int slot=(int)(sequence%2);
   return AB_WriteObjectSnapshot(slot,sequence,g_position_registry,
      g_breakout_registry,g_ladder_book,g_breakout_ladder_book,
      g_operation_ledger,g_basket_long,g_basket_short,g_straddle_state);
  }

bool HasRuntimeStateToPersist()
  {
   return g_position_registry.Count()>0 || g_breakout_registry.Count()>0 ||
          g_ladder_book.Count()>0 || g_breakout_ladder_book.Count()>0 ||
          g_operation_ledger.Count()>0 || g_basket_long.phase!=AB_BASKET_NONE ||
          g_basket_short.phase!=AB_BASKET_NONE || g_straddle_state.phase!=AB_STRADDLE_NONE;
  }

bool PersistRuntimeIfChanged(const bool force=false)
  {
   ulong fingerprint=RuntimeStateFingerprint();
   if(!force && fingerprint==g_last_runtime_fingerprint)
      return true;
   PersistRuntimeManifest();
   if(!g_persistence.Save() || !PersistObjectSnapshot())
      return false;
   g_last_runtime_fingerprint=fingerprint;
   return true;
  }

bool VerifyRecoveryEvidence()
  {
   if(!g_persistence.RecoveryRequiresHistoryCheck())
      return true;
   if(!g_persistence.RuntimeManifestMatches(g_position_registry.Count(),
      g_breakout_registry.Count(),g_ladder_book.Count(),g_breakout_ladder_book.Count()))
     {
      PrintFormat("AB_DIAG recovery evidence failed: manifest persisted normal=%d breakout=%d ladder=%d breakout_ladder=%d current normal=%d breakout=%d ladder=%d breakout_ladder=%d",
         g_persistence.PersistedNormalLineageCount(),
         g_persistence.PersistedBreakoutLineageCount(),
         g_persistence.PersistedNormalLadderCount(),
         g_persistence.PersistedBreakoutLadderCount(),
         g_position_registry.Count(),g_breakout_registry.Count(),
         g_ladder_book.Count(),g_breakout_ladder_book.Count());
      return false;
     }
   for(int i=0;i<g_position_registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!g_position_registry.GetAt(i,lineage))
        {
         PrintFormat("AB_DIAG recovery evidence failed: normal lineage read index=%d",i);
         return false;
        }
      if(!AB_VerifyPositionLineage(lineage))
        {
         PrintFormat("AB_DIAG recovery evidence failed: normal entity=%s position_id=%s ticket=%s symbol=%s",
            IntegerToString((long)lineage.entity_id.value),
            IntegerToString((long)lineage.position_identifier),
            IntegerToString((long)lineage.current_ticket),lineage.symbol);
         return false;
        }
     }
   for(int i=0;i<g_breakout_registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(i,lineage))
        {
         PrintFormat("AB_DIAG recovery evidence failed: breakout lineage read index=%d",i);
         return false;
        }
      if(!AB_VerifyBreakoutLineage(lineage))
        {
         PrintFormat("AB_DIAG recovery evidence failed: breakout entity=%s position_id=%s ticket=%s symbol=%s",
            IntegerToString((long)lineage.entity_id.value),
            IntegerToString((long)lineage.position_identifier),
            IntegerToString((long)lineage.current_ticket),lineage.symbol);
         return false;
        }
     }
   for(int i=0;i<g_operation_ledger.Count();i++)
     {
      AB_OperationRecord record;
      if(!g_operation_ledger.GetAt(i,record))
        {
         PrintFormat("AB_DIAG recovery evidence failed: operation read index=%d",i);
         return false;
        }
      if(!AB_VerifyOperationRecord(record) &&
         !(record.state==AB_OPERATION_UNKNOWN && record.request_id!=0 &&
           AB_IsIndependentBreakoutOperation(record,g_breakout_registry)))
        {
         PrintFormat("AB_DIAG recovery evidence failed: operation=%s entity=%s request=%s order=%s state=%d purpose=%d created=%s",
            IntegerToString((long)record.operation_id),
            IntegerToString((long)record.entity_id.value),
            IntegerToString((long)record.request_id),
            IntegerToString((long)record.order_ticket),
            (int)record.state,(int)record.purpose,
            TimeToString(record.created_at,TIME_DATE|TIME_SECONDS));
         return false;
        }
     }
   return true;
  }

bool AB_CurrentPositionExists(const ulong position_identifier)
  {
   if(position_identifier==0)
      return false;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket!=0 && PositionSelectByTicket(ticket) &&
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)==position_identifier)
         return true;
     }
   return false;
  }

bool AB_HistoryConfirmsPositionEnded(const ulong position_identifier)
  {
   if(position_identifier==0 || AB_CurrentPositionExists(position_identifier) ||
      !HistorySelect(0,TimeCurrent()))
      return false;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal!=0 && (ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID)==position_identifier)
         return true;
     }
   return false;
  }

int AB_ReconcileCandidateIndex(const ulong entity_id)
  {
   for(int i=0;i<g_reconcile_count;i++)
      if(g_reconcile_entities[i]==entity_id)
         return i;
   if(g_reconcile_count>=ArraySize(g_reconcile_entities))
      return -1;
   int index=g_reconcile_count++;
   g_reconcile_entities[index]=entity_id;
   g_reconcile_checks[index]=0;
   return index;
  }

void AB_RemoveReconcileCandidate(const ulong entity_id)
  {
   for(int i=0;i<g_reconcile_count;i++)
      if(g_reconcile_entities[i]==entity_id)
        {
         for(int j=i;j<g_reconcile_count-1;j++)
           {
            g_reconcile_entities[j]=g_reconcile_entities[j+1];
            g_reconcile_checks[j]=g_reconcile_checks[j+1];
           }
         g_reconcile_count--;
         return;
        }
  }

bool AB_ReconcileNormalMissing(const AB_PositionLineage &lineage)
  {
   if(!AB_HistoryConfirmsPositionEnded(lineage.position_identifier))
      return false;
   int index=AB_ReconcileCandidateIndex(lineage.entity_id.value);
   if(index<0)
      return false;
   g_reconcile_checks[index]++;
   if(g_reconcile_checks[index]<2)
      return false;
   g_position_registry.RemoveByEntity(lineage.entity_id);
   g_ladder_book.RemoveByEntity(lineage.entity_id);
   g_breakout_ladder_book.RemoveByEntity(lineage.entity_id);
   g_operation_ledger.RemoveByEntity(lineage.entity_id);
   AB_RemoveReconcileCandidate(lineage.entity_id.value);
   return true;
  }

bool AB_ReconcileBreakoutMissing(const AB_BreakoutLineage &lineage)
  {
   if(!AB_HistoryConfirmsPositionEnded(lineage.position_identifier))
      return false;
   int index=AB_ReconcileCandidateIndex(lineage.entity_id.value);
   if(index<0)
      return false;
   g_reconcile_checks[index]++;
   if(g_reconcile_checks[index]<2)
      return false;
   g_breakout_registry.RemoveByEntity(lineage.entity_id);
   g_breakout_ladder_book.RemoveByEntity(lineage.entity_id);
   g_operation_ledger.RemoveByEntity(lineage.entity_id);
   AB_RemoveReconcileCandidate(lineage.entity_id.value);
   return true;
  }

int AB_RunLedgerReconciliation(void)
  {
   int removed=0;
   for(int i=g_position_registry.Count()-1;i>=0;i--)
     {
      AB_PositionLineage lineage;
      if(!g_position_registry.GetAt(i,lineage))
         continue;
      if(!AB_CurrentPositionExists(lineage.position_identifier) && AB_ReconcileNormalMissing(lineage))
         removed++;
     }
   for(int i=g_breakout_registry.Count()-1;i>=0;i--)
     {
      AB_BreakoutLineage lineage;
      if(!g_breakout_registry.GetAt(i,lineage))
         continue;
      if(!AB_CurrentPositionExists(lineage.position_identifier) && AB_ReconcileBreakoutMissing(lineage))
         removed++;
     }
   AB_ClearEndedBasket(g_basket_long);
   AB_ClearEndedBasket(g_basket_short);
   if(removed>0)
     {
      PersistRuntimeIfChanged(true);
      PrintFormat("AB_DIAG ledger reconciliation removed ended entities=%d",removed);
     }
   return removed;
  }

bool AB_IsReconcileSlot(void)
  {
   datetime beijing=TimeGMT()+8*60*60;
   long slot=(long)(beijing/1800);
   if(slot==g_last_reconcile_slot)
      return false;
   MqlDateTime dt;
   TimeToStruct(beijing,dt);
   if(dt.min!=0 && dt.min!=30)
      return false;
   g_last_reconcile_slot=slot;
   return true;
  }

void AssignLevel(AB_LadderLevelInput &level,const double distance,const double ratio)
  {
   level.distance_micro_points=distance;
   level.close_ratio_percent=ratio;
  }

void LoadLadderConfig()
  {
   AssignLevel(g_ladder_config.normal[0],Normal_L1_Distance,Normal_L1_Ratio);
   AssignLevel(g_ladder_config.normal[1],Normal_L2_Distance,Normal_L2_Ratio);
   AssignLevel(g_ladder_config.normal[2],Normal_L3_Distance,Normal_L3_Ratio);
   AssignLevel(g_ladder_config.normal[3],Normal_L4_Distance,Normal_L4_Ratio);
   AssignLevel(g_ladder_config.normal[4],Normal_L5_Distance,Normal_L5_Ratio);
   AssignLevel(g_ladder_config.normal[5],Normal_L6_Distance,Normal_L6_Ratio);
   AssignLevel(g_ladder_config.normal[6],Normal_L7_Distance,Normal_L7_Ratio);
   AssignLevel(g_ladder_config.normal[7],Normal_L8_Distance,Normal_L8_Ratio);
   AssignLevel(g_ladder_config.normal[8],Normal_L9_Distance,Normal_L9_Ratio);
   AssignLevel(g_ladder_config.normal[9],Normal_L10_Distance,Normal_L10_Ratio);
   AssignLevel(g_ladder_config.breakout[0],Breakout_L1_Distance,Breakout_L1_Ratio);
   AssignLevel(g_ladder_config.breakout[1],Breakout_L2_Distance,Breakout_L2_Ratio);
   AssignLevel(g_ladder_config.breakout[2],Breakout_L3_Distance,Breakout_L3_Ratio);
   AssignLevel(g_ladder_config.breakout[3],Breakout_L4_Distance,Breakout_L4_Ratio);
   AssignLevel(g_ladder_config.breakout[4],Breakout_L5_Distance,Breakout_L5_Ratio);
   AssignLevel(g_ladder_config.breakout[5],Breakout_L6_Distance,Breakout_L6_Ratio);
   AssignLevel(g_ladder_config.breakout[6],Breakout_L7_Distance,Breakout_L7_Ratio);
   AssignLevel(g_ladder_config.breakout[7],Breakout_L8_Distance,Breakout_L8_Ratio);
   AssignLevel(g_ladder_config.breakout[8],Breakout_L9_Distance,Breakout_L9_Ratio);
   AssignLevel(g_ladder_config.breakout[9],Breakout_L10_Distance,Breakout_L10_Ratio);
  }

int ProcessReliableNormalAutomaticSL(const MqlTick &current_tick)
  {
   MqlTick opportunity_ticks[];
   AB_CopyNormalOpportunityTicks(_Symbol,current_tick,g_auto_sl_tick_cursor_msc,
                                 opportunity_ticks);
   if(g_runtime_auto_mode!=2)
      AB_CaptureNormalAutoSLTriggers(g_position_registry,g_auto_sl_trigger_latches,
         g_symbol_rules,opportunity_ticks,Normal_Auto_Trigger_MicroPoints);
   return AB_ProcessNormalAutomaticSLReliable(g_position_registry,g_operation_ledger,
      g_auto_sl_trigger_latches,g_symbol_rules,current_tick,g_basket_long,g_basket_short,
      g_runtime_auto_mode==0,Normal_Auto_Entry_Offset_MicroPoints,
      Normal_Auto_M1_Offset_MicroPoints);
  }

int OnInit()
  {
   g_ui_refresh.Reset();
   g_ui_initialized=false;
   g_runtime_start=TimeCurrent();
   g_auto_sl_trigger_latches.Reset();
   g_auto_sl_tick_cursor_msc=(ulong)g_runtime_start*1000;
   g_runtime_basket_trailing=MathMax(0,Basket_Trailing_MicroPoints);
   g_runtime_basket_reverse_close=MathMax(0,Basket_Reverse_Close_MicroPoints);
   g_runtime_basket_mode=Basket_Exit_Mode;
   g_runtime_auto_mode=Normal_Use_M1_Mode ? 0 : 1;
   g_runtime_ladder_enabled=true;
   g_runtime_trail[0]=MathMax(0,Normal_Trail_1_MicroPoints);
   g_runtime_trail[1]=MathMax(0,Normal_Trail_2_MicroPoints);
   g_runtime_trail[2]=MathMax(0,Normal_Trail_3_MicroPoints);
   g_runtime_trail[3]=MathMax(0,Normal_Trail_4_MicroPoints);
   g_runtime_close_ratio[0]=Normal_Manual_Close_1_Ratio;
   g_runtime_close_ratio[1]=Normal_Manual_Close_2_Ratio;
   g_runtime_close_ratio[2]=Normal_Manual_Close_3_Ratio;
   g_runtime_close_ratio[3]=Normal_Manual_Close_4_Ratio;
   g_runtime_tp_label_font_size=MathMax(6,MathMin(14,TP_Label_Font_Size));
   g_runtime_panel_x=MathMax(0,Panel_Default_X);
   g_runtime_panel_y=MathMax(0,Panel_Default_Y);
   g_runtime_log_history=MathMax(1,MathMin(20,Panel_Log_History));
   g_panel_log.Clear();
   g_panel_log.SetCapacity(g_runtime_log_history);
   LoadLadderConfig();
   if(!AB_LoadSymbolRules(_Symbol,g_symbol_rules))
      return INIT_FAILED;
    if(!g_persistence.LoadLatest())
       return INIT_FAILED;
    bool local_state_present=g_persistence.HasCommittedState();
    g_first_local_rebuild=!local_state_present;
   PrintRecoveryDiagnostic("after LoadLatest");
    if(local_state_present)
     {
      int slot=(int)(g_persistence.Sequence()%2);
      if(!AB_ReadObjectSnapshot(slot,g_persistence.Sequence(),g_position_registry,
         g_breakout_registry,g_ladder_book,g_breakout_ladder_book,
         g_operation_ledger,g_basket_long,g_basket_short,g_straddle_state))
         {
          PrintFormat("AB_DIAG recovery snapshot read failed sequence=%s slot=%d",
             IntegerToString((long)g_persistence.Sequence()),slot);
          g_persistence.SetRecoveryRequired(true);
         }
      }
   int resolved_unsubmitted_unknown=g_operation_ledger.ResolveUnsubmittedUnknownOperations();
   if(resolved_unsubmitted_unknown>0)
      PrintFormat("AB_DIAG resolved unsubmitted unknown operations count=%d",
         resolved_unsubmitted_unknown);
   int resolved_stale_pending_close=g_operation_ledger.ResolveStalePendingCloseOperations(g_runtime_start);
   if(resolved_stale_pending_close>0)
      PrintFormat("AB_DIAG resolved stale pending close operations count=%d",
         resolved_stale_pending_close);
   for(int stale_index=0;stale_index<g_operation_ledger.Count();stale_index++)
     {
      AB_OperationRecord stale_operation;
      if(!g_operation_ledger.GetAt(stale_index,stale_operation) ||
         stale_operation.state!=AB_OPERATION_REJECTED)
         continue;
      g_position_registry.RejectSLPending(stale_operation.operation_id);
      g_breakout_registry.RejectSLPending(stale_operation.operation_id);
      g_ladder_book.RejectByOperation(stale_operation.operation_id);
      g_breakout_ladder_book.RejectByOperation(stale_operation.operation_id,stale_operation.completed_volume);
      AB_BasketRejectOperation(g_basket_long,stale_operation.operation_id);
      AB_BasketRejectOperation(g_basket_short,stale_operation.operation_id);
     }
    int registered_positions=0;
    int registered_breakout=0;
    AB_RunLedgerReconciliation();
   bool recovery_was_required=g_persistence.RecoveryRequiresHistoryCheck();
   PrintRecoveryDiagnostic("before recovery verification");
   bool recovery_verified=VerifyRecoveryEvidence();
   PrintFormat("AB_DIAG recovery verification result=%s previous_required=%s",
      recovery_verified ? "true" : "false",
      recovery_was_required ? "true" : "false");
   if(!recovery_verified)
     {
      Print("AB_DIAG recovery remains locked: evidence verification failed");
      g_persistence.SetRecoveryRequired(true);
     }
   else if(g_persistence.HasUnknownRequest())
     {
      if(!g_persistence.ResolveUnknownRequestAfterHistoryCheck(true))
         return INIT_FAILED;
     }
    else if(g_persistence.RecoveryRequiresHistoryCheck())
      {
       Print("AB_DIAG recovery evidence verified; clearing recovery lock");
       g_persistence.SetRecoveryRequired(false);
      }
    PrintRecoveryDiagnostic("after recovery resolution");
    datetime registration_start=g_first_local_rebuild ? (datetime)0 : g_runtime_start;
    registered_positions=AB_RegisterEligibleNormalPositions(g_position_registry,g_persistence,
       _Symbol,CurrentSymbolOnly,Normal_Managed_Magic,Straddle_Magic,registration_start);
    registered_breakout=AB_RegisterBreakoutPositions(g_breakout_registry,g_persistence,
       _Symbol,Straddle_Magic,registration_start);
   PrintFormat("AB_DIAG post-recovery registration normal=%d breakout=%d",
      registered_positions,registered_breakout);
   int rearmed_automatic_sl=0;
    if(g_persistence.CanIssueNewActions())
       rearmed_automatic_sl=AB_RearmMissingAutomaticSLState(g_position_registry,
          g_basket_long,g_basket_short);
    PersistRuntimeManifest();
    if((registered_positions>0 || registered_breakout>0 || recovery_was_required ||
        g_first_local_rebuild ||
        rearmed_automatic_sl>0 || g_persistence.RecoveryRequiresHistoryCheck()) &&
       !g_persistence.Save())
       return INIT_FAILED;
   if(!PersistObjectSnapshot())
      return INIT_FAILED;
   g_last_runtime_fingerprint=RuntimeStateFingerprint();
   g_engine_snapshot=AB_EmptyEngineSnapshot(0,!g_persistence.CanIssueNewActions());
   PrintRecoveryDiagnostic("oninit complete");
   g_runtime_state.last_phase=AB_RUNTIME_RECOVER_UNKNOWN;
   g_runtime_state.state_version=0;
   g_runtime_state.recovery_gate=g_engine_snapshot.recovery_gate;
   g_runtime_state.current_tick_seen=false;
   g_runtime_state.high_priority_submitted=false;
   g_panel.Configure(BuildPanelConfig());
   if(!g_panel.Create(ChartID()))
     {
      PrintFormat("静态面板对象创建失败: %s, error=%d",
                  g_panel.LastFailedObject(),g_panel.LastFailedError());
      AB_CleanupAllChartVisualizationObjects();
      g_panel.Destroy();
      return INIT_FAILED;
     }
   g_dynamic_layers.Configure(ChartID(),g_panel.CanvasX(),g_panel.CanvasY(),_Digits);
   if(!g_dynamic_layers.Create())
     {
      PrintFormat("动态面板对象创建失败: %s, error=%d",
                  g_dynamic_layers.LastFailedObject(),
                  g_dynamic_layers.LastFailedError());
      AB_CleanupAllChartVisualizationObjects();
      g_dynamic_layers.Destroy();
      g_panel.Destroy();
      return INIT_FAILED;
     }
   RequestChartVisualizationRefresh();
   g_ui_initialized=true;
   g_ui_refresh.Mark(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|
                     AB_UI_DIRTY_BASKET|AB_UI_DIRTY_LOG|AB_UI_DIRTY_CHART);
   bool timer_started=EventSetMillisecondTimer(250);
   if(!timer_started)
     {
      PrintFormat("面板定时器启动失败, error=%d",GetLastError());
      g_ui_initialized=false;
      EventKillTimer();
      AB_CleanupAllChartVisualizationObjects();
      g_dynamic_layers.Destroy();
      g_panel.Destroy();
      return INIT_FAILED;
     }
   FlushUiRefresh();
   return INIT_SUCCEEDED;
  }

void OnTick()
  {
   g_ui_refresh.Mark(AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_BASKET|
                     AB_UI_DIRTY_LOG|AB_UI_DIRTY_CHART);
   int new_normal=AB_RegisterEligibleNormalPositions(g_position_registry,g_persistence,
      _Symbol,CurrentSymbolOnly,Normal_Managed_Magic,Straddle_Magic,g_runtime_start);
   int new_breakout=AB_RegisterBreakoutPositions(g_breakout_registry,g_persistence,
      _Symbol,Straddle_Magic,g_runtime_start);
   if(new_normal>0 || new_breakout>0)
     {
      PersistRuntimeManifest();
      if(g_persistence.Save())
         PersistObjectSnapshot();
     }
   AB_ReconcileStraddleLifecycleV32_12(g_straddle_state,g_operation_ledger,
      _Symbol,Straddle_Magic);
   bool recovery_gate=!g_persistence.CanIssueNewActions();
   if(!g_diag_recovery_gate_initialized || recovery_gate!=g_diag_last_recovery_gate)
     {
      g_diag_recovery_gate_initialized=true;
      g_diag_last_recovery_gate=recovery_gate;
      PrintRecoveryDiagnostic("OnTick gate transition");
     }
   g_engine_snapshot.recovery_gate=recovery_gate;
   g_engine_snapshot=AB_BuildEngineSnapshot(g_position_registry,g_breakout_registry,
      g_basket_long,g_basket_short,g_runtime_state.state_version,g_engine_snapshot.recovery_gate);
   AB_RuntimeBeginTick(g_runtime_state,g_engine_snapshot);
   if(!AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_RECOVER_UNKNOWN,true))
      return;
   if(!AB_RuntimeAllowsNewPriceOpportunity(g_engine_snapshot))
      return;
   AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_BREAKOUT_SETTLEMENT,true);
   if(g_straddle_state.phase==AB_STRADDLE_ROLLING_BACK)
      AB_ProcessStraddleRollback(g_straddle_state,g_operation_ledger,_Symbol,Straddle_Magic);
   else if(g_straddle_state.phase==AB_STRADDLE_SETTLING)
     {
      MqlTick settlement_tick;
      if(SymbolInfoTick(_Symbol,settlement_tick))
         AB_ProcessBreakoutSettlement(g_straddle_state,g_breakout_registry,
            g_operation_ledger,g_symbol_rules,settlement_tick,_Symbol,
            Straddle_Magic,Slippage_MicroPoints);
     }
   if(AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_BREAKOUT_MANAGEMENT,true))
     {
      MqlTick breakout_tick;
      if(SymbolInfoTick(_Symbol,breakout_tick))
         AB_ProcessBreakoutManagement(g_breakout_registry,g_breakout_ladder_book,
            g_operation_ledger,g_symbol_rules,breakout_tick,
            Straddle_Initial_SL_MicroPoints,Straddle_BE_Trigger_MicroPoints,
            Straddle_BE_Lock_MicroPoints,g_ladder_config.breakout,Slippage_MicroPoints);
      AB_CancelBreakoutPendingOrdersV32_12(g_operation_ledger,
                                           _Symbol,Straddle_Magic);
      if(g_straddle_state.opposite_cancel_pending)
        {
         bool opposite_exists=false;
         for(int i=0;i<OrdersTotal();i++)
           {
            ulong order_ticket=OrderGetTicket(i);
            if(order_ticket!=0 && OrderGetString(ORDER_SYMBOL)==_Symbol &&
               (long)OrderGetInteger(ORDER_MAGIC)==Straddle_Magic &&
               AB_IsStraddlePendingOrderTypeV32_12(
                  (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
               opposite_exists=true;
           }
         if(!opposite_exists)
            AB_RecordOppositeCancelComplete(g_straddle_state);
        }
     }
   if(AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_BASKET_CLEANUP,true))
     {
      MqlTick cleanup_tick;
      if(SymbolInfoTick(_Symbol,cleanup_tick))
        {
         AB_ProcessBasketCancellation(g_basket_long,g_operation_ledger,g_symbol_rules,cleanup_tick);
         AB_ProcessBasketCancellation(g_basket_short,g_operation_ledger,g_symbol_rules,cleanup_tick);
        }
     }
   if(AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_BASKET_EXIT,true))
     {
      MqlTick basket_tick;
      if(SymbolInfoTick(_Symbol,basket_tick))
        {
         AB_ProcessBasketExitV32_11(g_basket_long,g_operation_ledger,g_symbol_rules,basket_tick,
            g_runtime_basket_trailing,g_runtime_basket_reverse_close,Slippage_MicroPoints);
         AB_ProcessBasketExitV32_11(g_basket_short,g_operation_ledger,g_symbol_rules,basket_tick,
            g_runtime_basket_trailing,g_runtime_basket_reverse_close,Slippage_MicroPoints);
        }
     }
   AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_MANUAL_CLOSE,false);
   if(AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_NORMAL_SL,false))
     {
      MqlTick tick;
      if(SymbolInfoTick(_Symbol,tick))
        {
         AB_ProcessNormalTrailingSL(g_position_registry,g_operation_ledger,g_symbol_rules,tick,
            g_basket_long,g_basket_short,Normal_Trail_Min_Step_MicroPoints);
         ProcessReliableNormalAutomaticSL(tick);
        }
     }
   if(g_runtime_ladder_enabled && AB_RuntimeEnterPhase(g_runtime_state,AB_RUNTIME_NORMAL_LADDER,false))
     {
      MqlTick tick;
      if(SymbolInfoTick(_Symbol,tick))
         AB_ProcessNormalLadder(g_position_registry,g_ladder_book,g_operation_ledger,
            g_symbol_rules,tick,g_ladder_config.normal,Slippage_MicroPoints,
            g_basket_long,g_basket_short);
     }
   if(HasRuntimeStateToPersist())
      PersistRuntimeIfChanged();
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_ui_initialized=false;
   AB_CleanupAllChartVisualizationObjects();
   g_dynamic_layers.Destroy();
   g_panel.Destroy();
  }

int g_ledger_full_reported_count=0;
datetime g_ledger_full_reported_at=0;

void ReportLedgerFullIfNeeded()
  {
   int rejects=g_operation_ledger.FullRejectCount();
   if(rejects==g_ledger_full_reported_count)
      return;
   datetime now=TimeCurrent();
   if(g_ledger_full_reported_at>0 && now-g_ledger_full_reported_at<60)
      return;
   g_ledger_full_reported_count=rejects;
   g_ledger_full_reported_at=now;
   PrintFormat("AB_DIAG operation ledger full: records=%d rejected_requests=%d",
      g_operation_ledger.Count(),rejects);
   g_panel_log.Add(now,"操作记录已满（"+IntegerToString(g_operation_ledger.Count())+
                   " 条），新的交易请求被暂停。");
   RequestUiRefresh(AB_UI_DIRTY_LOG);
  }

void OnTimer()
  {
   bool breakout_reconciled=AB_ReconcileBreakoutClosures(g_breakout_registry,
                              g_breakout_ladder_book,g_operation_ledger)>0;
   AB_ReconcileBreakoutSL(g_breakout_registry,g_operation_ledger,g_symbol_rules,
                          Straddle_Initial_SL_MicroPoints,Straddle_BE_Lock_MicroPoints);
   if(breakout_reconciled) PersistRuntimeIfChanged(true);
   if(AB_IsReconcileSlot())
     {
      AB_RunLedgerReconciliation();
      PersistRuntimeIfChanged(true);
     }
   if(AB_ReconcileStraddleLifecycleV32_12(g_straddle_state,g_operation_ledger,
      _Symbol,Straddle_Magic))
      PersistRuntimeIfChanged(true);
   if(g_persistence.CanIssueNewActions())
     {
      MqlTick tick;
      if(SymbolInfoTick(_Symbol,tick) && ProcessReliableNormalAutomaticSL(tick)>0)
         PersistRuntimeIfChanged(true);
     }
   ReportLedgerFullIfNeeded();
   FlushUiRefresh();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,
                  const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      ulong visualization_ticket=AB_VisualizationPositionTicket(sparam);
      if(visualization_ticket!=0)
        {
         if(SelectChartPosition(visualization_ticket))
            MarkOrderSelectionObjectClick();
         RequestUiRefresh(AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_LOG);
         RequestChartVisualizationRefresh();
         return;
        }
      if(g_panel.IsPanelObject(sparam))
        {
         if(HandlePanelClickAt((int)lparam,(int)dparam))
            MarkPanelObjectClick();
         return;
        }
      if(g_dynamic_layers.IsLayerObject(sparam))
        {
         MarkPanelObjectClick();
         HandlePanelClickAt((int)lparam,(int)dparam);
         return;
        }
      return;
     }
   if(id==CHARTEVENT_CLICK)
     {
      if(ShouldIgnoreChartClickAfterOrderObjectClick() ||
         ShouldIgnoreChartClickAfterPanelObjectClick())
         return;
      if(HandlePanelClickAt((int)lparam,(int)dparam))
         return;
      ClearSelectedPosition();
      RequestUiRefresh(AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_LOG);
      RequestChartVisualizationRefresh();
      return;
     }
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      RequestUiRefresh(AB_UI_DIRTY_STATIC|AB_UI_DIRTY_LAYOUT|
                       AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_BASKET|
                       AB_UI_DIRTY_LOG);
      RequestChartVisualizationRefresh();
      RequestChartVisualizationDelayedPasses(3);
      return;
     }
  }

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   AB_OperationRecord operation;
   bool operation_updated=AB_HandleTradeTransaction(transaction,result,g_operation_ledger,operation);
   if(transaction.type==TRADE_TRANSACTION_ORDER_ADD && transaction.order!=0 &&
      OrderSelect(transaction.order) &&
      (long)OrderGetInteger(ORDER_MAGIC)==Straddle_Magic)
     {
      ENUM_ORDER_TYPE order_type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(order_type==ORDER_TYPE_BUY_STOP)
         AB_RecordStraddleOrderTicket(g_straddle_state,true,transaction.order);
      else if(order_type==ORDER_TYPE_SELL_STOP)
         AB_RecordStraddleOrderTicket(g_straddle_state,false,transaction.order);
     }
   if(transaction.type==TRADE_TRANSACTION_DEAL_ADD && transaction.deal!=0 &&
      HistoryDealGetInteger(transaction.deal,DEAL_MAGIC)==Straddle_Magic &&
      (ENUM_DEAL_ENTRY)HistoryDealGetInteger(transaction.deal,DEAL_ENTRY)==DEAL_ENTRY_IN)
     {
      ulong position_identifier=(ulong)HistoryDealGetInteger(transaction.deal,DEAL_POSITION_ID);
      double fill_price=HistoryDealGetDouble(transaction.deal,DEAL_PRICE);
      AB_RecordStraddleFill(g_straddle_state,position_identifier,fill_price);
     }
   ulong unknown_request_id=0;
   if(AB_FirstBlockingUnknownRequest(g_operation_ledger,g_breakout_registry,unknown_request_id))
     {
      PrintFormat("AB_DIAG unknown request detected id=%s",
         IntegerToString((long)unknown_request_id));
      g_persistence.SetUnknownRequestId(unknown_request_id);
      PersistRuntimeManifest();
      g_persistence.Save();
     }
   if(operation_updated &&
       operation.purpose==AB_PURPOSE_SLTP && operation.state==AB_OPERATION_COMPLETED)
       g_position_registry.MarkSLCompleted(operation.entity_id,operation.operation_id);
   if(operation_updated &&
      (operation.state==AB_OPERATION_REJECTED || operation.state==AB_OPERATION_TEMPORARY))
     {
      g_position_registry.RejectSLPending(operation.operation_id);
      g_breakout_registry.RejectSLPending(operation.operation_id);
      g_ladder_book.RejectByOperation(operation.operation_id);
      g_breakout_ladder_book.RejectByOperation(operation.operation_id,operation.completed_volume);
      AB_BasketRejectOperation(g_basket_long,operation.operation_id);
      AB_BasketRejectOperation(g_basket_short,operation.operation_id);
     }
   if(operation_updated &&
      operation.purpose==AB_PURPOSE_CLOSE && operation.state==AB_OPERATION_COMPLETED)
     {
      g_ladder_book.CompleteByOperation(operation.operation_id);
      g_breakout_ladder_book.CompleteByOperation(operation.operation_id);
     }
   if(operation_updated &&
      operation.purpose==AB_PURPOSE_SLTP && operation.state==AB_OPERATION_COMPLETED)
      g_breakout_registry.MarkSLCompleted(operation.operation_id);
    if(operation_updated &&
       operation.state==AB_OPERATION_COMPLETED)
      {
       AB_BasketCompleteOperation(g_basket_long,operation.operation_id);
       AB_BasketCompleteOperation(g_basket_short,operation.operation_id);
      }
   AB_ReconcileStraddleLifecycleV32_12(g_straddle_state,g_operation_ledger,
      _Symbol,Straddle_Magic);
   PersistRuntimeIfChanged(true);
   RequestUiRefresh(AB_UI_DIRTY_HEADER|AB_UI_DIRTY_ORDER|AB_UI_DIRTY_BASKET|
                    AB_UI_DIRTY_LOG);
   RequestChartVisualizationRefresh();
  }


