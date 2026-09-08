#ifndef AB_CHART_VIEW_MQH
#define AB_CHART_VIEW_MQH

#include "AB_CanvasPanel.mqh"
#include "AB_PositionRegistry.mqh"
#include "AB_LadderEngine.mqh"
#include "AB_StraddleEngine.mqh"
#include "AB_BasketEngine.mqh"

#define AB_VISUALIZATION_PREFIX_ROOT "ABV31_02_VIS_"

struct AB_ChartLabelPlacement
  {
   int column;
   int x;
   int y;
   int width;
   int line_height;
  };

string AB_VisualizationPrefix(void)
  {
   return AB_VISUALIZATION_PREFIX_ROOT+IntegerToString((long)ChartID())+"_";
  }

ulong AB_VisualizationPositionTicket(const string object_name)
  {
   string marker=AB_VisualizationPrefix()+"ORDER_";
   if(StringFind(object_name,marker)!=0)
      return 0;
   int start=StringLen(marker);
   int separator=StringFind(object_name,"_",start);
   if(separator<=start)
      return 0;
   long parsed=StringToInteger(StringSubstr(object_name,start,separator-start));
   if(parsed<=0)
      return 0;
   return (ulong)parsed;
  }

void AB_AddExpectedVisualizationObject(string &names[],const string name)
  {
   int size=ArraySize(names);
   ArrayResize(names,size+1);
   names[size]=name;
  }

bool AB_IsExpectedVisualizationObject(const string name,const string &names[])
  {
   for(int i=0;i<ArraySize(names);i++)
      if(names[i]==name)
         return true;
   return false;
  }

void AB_DeleteUnexpectedVisualizationObjects(const string &expected_names[])
  {
   string prefix=AB_VisualizationPrefix();
   int total=ObjectsTotal(0,0,-1);
   for(int i=total-1;i>=0;i--)
     {
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,prefix)!=0)
         continue;
      if(!AB_IsExpectedVisualizationObject(name,expected_names))
         ObjectDelete(0,name);
     }
  }

void AB_CleanupAllChartVisualizationObjects(void)
  {
   string prefix=AB_VisualizationPrefix();
   int total=ObjectsTotal(0,0,-1);
   for(int i=total-1;i>=0;i--)
     {
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,prefix)==0)
         ObjectDelete(0,name);
     }
  }

int AB_ClampInt(const int value,const int low,const int high)
  {
   if(value<low)
      return low;
   if(value>high)
      return high;
   return value;
  }

int AB_LotDigitsFromStep(double step)
  {
   if(step<=0.0)
      return 2;
   double scaled=step;
   for(int digits=0;digits<=8;digits++)
     {
      if(MathAbs(scaled-MathRound(scaled))<0.00000001)
         return digits;
      scaled*=10.0;
     }
   return 8;
  }

int AB_EstimateChartLabelWidth(const string text,const int font_size)
  {
   int width=16;
   for(int i=0;i<StringLen(text);i++)
     {
      int char_code=StringGetCharacter(text,i);
      if(char_code>=0x2E80)
         width+=font_size+4;
      else if(char_code>=48 && char_code<=57)
         width+=font_size;
      else if(char_code==32)
         width+=MathMax(4,font_size/2);
      else
         width+=font_size+1;
     }
   return MathMax(64,width);
  }

bool AB_SetIntegerIfChanged(const long chart_id,const string name,
                            const ENUM_OBJECT_PROPERTY_INTEGER property,
                            const long value)
  {
   if(ObjectGetInteger(chart_id,name,property)==value)
      return true;
   return ObjectSetInteger(chart_id,name,property,value);
  }

bool AB_SetStringIfChanged(const long chart_id,const string name,
                           const ENUM_OBJECT_PROPERTY_STRING property,
                           const string value)
  {
   if(ObjectGetString(chart_id,name,property)==value)
      return true;
   return ObjectSetString(chart_id,name,property,value);
  }

bool AB_MoveObjectIfChanged(const long chart_id,const string name,
                            const int point_index,const datetime time,
                            const double price)
  {
   datetime current_time=(datetime)ObjectGetInteger(chart_id,name,OBJPROP_TIME,point_index);
   double current_price=ObjectGetDouble(chart_id,name,OBJPROP_PRICE,point_index);
   if(current_time==time && MathAbs(current_price-price)<=0.0000000001)
      return true;
   return ObjectMove(chart_id,name,point_index,time,price);
  }

bool AB_GetChartTimeAtRatio(const double ratio,datetime &chart_time)
  {
   long chart_width=ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   if(chart_width<=0)
      return false;
   int x=(int)MathRound((double)chart_width*ratio);
   int sub_window=0;
   double price=0.0;
   if(!ChartXYToTimePrice(0,x,10,sub_window,chart_time,price))
      return false;
   return sub_window==0;
  }

bool AB_GetChartLabelReferenceTime(datetime &chart_time)
  {
   if(AB_GetChartTimeAtRatio(0.95,chart_time))
      return true;
   if(AB_GetChartTimeAtRatio(0.75,chart_time))
      return true;
   if(AB_GetChartTimeAtRatio(0.50,chart_time))
      return true;
   chart_time=TimeCurrent();
   return chart_time>0;
  }

int AB_AllocateLabelColumn(const int desired_y,
                           const int label_width,
                           const int line_height,
                           AB_ChartLabelPlacement &placements[])
  {
   int chart_width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int column_step=240;
   for(int column=0;column<12;column++)
     {
      int x=chart_width-24-label_width-column*column_step;
      if(x<0)
         x=0;
      bool overlaps=false;
      for(int i=0;i<ArraySize(placements);i++)
        {
         if(placements[i].column!=column)
            continue;
         int compared_height=MathMax(line_height,placements[i].line_height);
         if(MathAbs(desired_y-placements[i].y)<compared_height+3)
           {
            overlaps=true;
            break;
           }
        }
      if(overlaps)
         continue;
      int size=ArraySize(placements);
      ArrayResize(placements,size+1);
      placements[size].column=column;
      placements[size].x=x;
      placements[size].y=desired_y;
      placements[size].width=label_width;
      placements[size].line_height=line_height;
      return column;
     }
   int fallback=ArraySize(placements);
   ArrayResize(placements,fallback+1);
   placements[fallback].column=11;
   placements[fallback].x=0;
   placements[fallback].y=desired_y;
   placements[fallback].width=label_width;
   placements[fallback].line_height=line_height;
   return 11;
  }

bool AB_CreateOrUpdatePixelLabel(const string name,
                                 const string text,
                                 const double price,
                                 const color text_color,
                                 const bool selectable,
                                 const bool selected,
                                 const int label_font_size,
                                 AB_ChartLabelPlacement &placements[])
  {
   int price_x=0;
   int price_y=0;
   datetime reference_time=0;
   if(!AB_GetChartLabelReferenceTime(reference_time) ||
      !ChartTimePriceToXY(0,0,reference_time,price,price_x,price_y))
      return false;
   int font_size=AB_ClampInt(label_font_size>0 ? label_font_size : 8,6,14);
   int line_height=font_size+5;
   int label_width=AB_EstimateChartLabelWidth(text,font_size);
   int chart_height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
   int max_y=MathMax(0,chart_height-line_height);
   int desired_y=AB_ClampInt(price_y-line_height,0,max_y);
   AB_AllocateLabelColumn(desired_y,label_width,line_height,placements);
   int placement_index=ArraySize(placements)-1;
   int label_x=placement_index>=0 ? placements[placement_index].x : 0;

   if(ObjectFind(0,name)>=0 &&
      (ENUM_OBJECT)ObjectGetInteger(0,name,OBJPROP_TYPE)!=OBJ_LABEL)
      ObjectDelete(0,name);
   if(ObjectFind(0,name)<0)
     {
      ResetLastError();
      if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
        {
         Print("阶梯可视化：创建像素文字失败，对象=",name,
               " 错误代码: ",GetLastError());
         return false;
        }
     }
   AB_SetIntegerIfChanged(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   AB_SetIntegerIfChanged(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   AB_SetIntegerIfChanged(0,name,OBJPROP_XDISTANCE,label_x);
   AB_SetIntegerIfChanged(0,name,OBJPROP_YDISTANCE,desired_y);
   AB_SetStringIfChanged(0,name,OBJPROP_TEXT,text);
   AB_SetStringIfChanged(0,name,OBJPROP_FONT,"Noto Sans SC");
   AB_SetIntegerIfChanged(0,name,OBJPROP_COLOR,selected ? clrGold : text_color);
   AB_SetIntegerIfChanged(0,name,OBJPROP_FONTSIZE,font_size);
   AB_SetIntegerIfChanged(0,name,OBJPROP_SELECTABLE,selectable);
   AB_SetIntegerIfChanged(0,name,OBJPROP_SELECTED,false);
   AB_SetIntegerIfChanged(0,name,OBJPROP_HIDDEN,true);
   AB_SetIntegerIfChanged(0,name,OBJPROP_ZORDER,selectable ? 20 : 5);
   return true;
  }

color AB_ChartTradeColor(const int display_number,const bool breakout)
  {
   int slot=((display_number-1)*2+(breakout ? 1 : 0))%20;
   if(slot==0) return clrDeepSkyBlue;
   if(slot==1) return clrOrangeRed;
   if(slot==2) return clrLimeGreen;
   if(slot==3) return clrGold;
   if(slot==4) return clrMagenta;
   if(slot==5) return clrAqua;
   if(slot==6) return clrDeepPink;
   if(slot==7) return clrYellow;
   if(slot==8) return clrSpringGreen;
   if(slot==9) return clrTomato;
   if(slot==10) return clrViolet;
   if(slot==11) return clrLightSkyBlue;
   if(slot==12) return clrChartreuse;
   if(slot==13) return clrOrange;
   if(slot==14) return clrHotPink;
   if(slot==15) return clrTurquoise;
   if(slot==16) return clrLightSalmon;
   if(slot==17) return clrPlum;
   if(slot==18) return clrMediumPurple;
   return clrWhite;
  }

double AB_LevelChartPrice(const double open_price,
                          const ENUM_POSITION_TYPE position_type,
                          const double distance_micro_points,
                          const AB_SymbolRules &rules,
                          const MqlTick &tick)
  {
   double distance=distance_micro_points*rules.point;
   double target=position_type==POSITION_TYPE_BUY
      ? open_price+distance
      : open_price-distance;
   if(position_type==POSITION_TYPE_SELL)
     {
      double spread=tick.ask-tick.bid;
      if(tick.ask<=0.0 || tick.bid<=0.0 || spread<0.0)
         spread=0.0;
      target-=spread;
     }
   return NormalizeDouble(target,rules.digits);
  }

bool AB_CreateOrUpdateLevelLine(const string name,
                                const double target_price,
                                const color line_color,
                                const TPLineDisplayMode line_mode)
  {
   if(line_mode==TP_LINE_OFF)
      return false;
   ENUM_OBJECT required_type=line_mode==TP_LINE_SHORT ? OBJ_TREND : OBJ_HLINE;
   if(ObjectFind(0,name)>=0 &&
      (ENUM_OBJECT)ObjectGetInteger(0,name,OBJPROP_TYPE)!=required_type)
      ObjectDelete(0,name);
   if(line_mode==TP_LINE_SHORT)
     {
      datetime left_time=TimeCurrent();
      datetime right_time=TimeCurrent();
      if(!AB_GetChartTimeAtRatio(0.68,left_time) ||
         !AB_GetChartTimeAtRatio(0.98,right_time))
         return false;
      if(ObjectFind(0,name)<0)
        {
         ResetLastError();
         if(!ObjectCreate(0,name,OBJ_TREND,0,left_time,target_price,right_time,target_price))
           {
            Print("阶梯可视化：创建短线失败，对象=",name,
                  " 错误代码: ",GetLastError());
            return false;
           }
        }
      AB_MoveObjectIfChanged(0,name,0,left_time,target_price);
      AB_MoveObjectIfChanged(0,name,1,right_time,target_price);
      AB_SetIntegerIfChanged(0,name,OBJPROP_RAY_RIGHT,true);
     }
   else if(line_mode==TP_LINE_FULL)
     {
      if(ObjectFind(0,name)<0)
        {
         ResetLastError();
         if(!ObjectCreate(0,name,OBJ_HLINE,0,0,target_price))
           {
            Print("阶梯可视化：创建全图线失败，对象=",name,
                  " 错误代码: ",GetLastError());
            return false;
           }
        }
      AB_MoveObjectIfChanged(0,name,0,0,target_price);
     }
   else
      return false;
   AB_SetIntegerIfChanged(0,name,OBJPROP_COLOR,line_color);
   AB_SetIntegerIfChanged(0,name,OBJPROP_STYLE,STYLE_DASH);
   AB_SetIntegerIfChanged(0,name,OBJPROP_WIDTH,1);
   AB_SetIntegerIfChanged(0,name,OBJPROP_SELECTABLE,false);
   AB_SetIntegerIfChanged(0,name,OBJPROP_SELECTED,false);
   AB_SetIntegerIfChanged(0,name,OBJPROP_HIDDEN,true);
   return true;
  }

string AB_OpenAliasText(const string alias,
                        const double open_price,
                        const ENUM_POSITION_TYPE position_type,
                        const AB_SymbolRules &rules,
                        const MqlTick &tick)
  {
   double delta=position_type==POSITION_TYPE_BUY
      ? tick.bid-open_price
      : open_price-tick.ask;
   delta=NormalizeDouble(delta,rules.digits);
   string sign=delta>=0.0 ? "+" : "";
   return alias+" "+sign+DoubleToString(delta,rules.digits);
  }

string AB_LevelLabelText(const string alias,
                         const int level_index,
                         const AB_LadderLevelState &level,
                         const double close_volume,
                         const AB_SymbolRules &rules)
  {
   string text=alias+"-L"+IntegerToString(level_index+1)+
      " | +"+IntegerToString((int)MathRound(level.distance_micro_points))+"点";
   int lot_digits=AB_LotDigitsFromStep(rules.volume_step);
   text+=" | 平"+DoubleToString(close_volume,lot_digits)+"手";
   if(level.pending_request && !level.completed)
      text+=" | 待执行/待重试";
   return text;
  }

void AB_AddPositionVisualization(const ulong ticket,
                                 const string alias,
                                 const bool breakout,
                                 const AB_LadderPositionState &ladder_state,
                                 const AB_LadderLevelInput &ladder_inputs[],
                                 const AB_SymbolRules &rules,
                                 const MqlTick &tick,
                                 const bool suppress_ladder,
                                 const TPLineDisplayMode line_mode,
                                 const int label_font_size,
                                 const ulong selected_ticket,
                                 string &expected_names[],
                                 AB_ChartLabelPlacement &placements[])
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return;
   ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
      return;
   double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   string object_base=AB_VisualizationPrefix()+"ORDER_"+IntegerToString((long)ticket);
   string open_name=object_base+"_OPEN";
   int display_number=(int)StringToInteger(StringSubstr(alias,1));
   color trade_color=AB_ChartTradeColor(display_number,breakout);
   AB_AddExpectedVisualizationObject(expected_names,open_name);
   AB_CreateOrUpdatePixelLabel(open_name,
                               AB_OpenAliasText(alias,open_price,position_type,rules,tick),
                               open_price,trade_color,true,selected_ticket==ticket,
                               label_font_size,placements);
   if(line_mode==TP_LINE_OFF || suppress_ladder)
      return;
   AB_LadderPositionState state=ladder_state;
   state.current_volume=PositionGetDouble(POSITION_VOLUME);
   if(state.original_volume<=0.0)
      state.original_volume=state.current_volume;
   for(int level=0;level<10;level++)
     {
      if(!AB_IsLadderLevelEnabled(ladder_inputs[level]))
         continue;
      AB_LadderLevelState level_state=state.levels[level];
      if(!level_state.enabled)
        {
         level_state.enabled=true;
         level_state.distance_micro_points=ladder_inputs[level].distance_micro_points;
         level_state.ratio_percent=ladder_inputs[level].close_ratio_percent;
        }
      if(level_state.completed)
         continue;
      double close_volume=AB_ComputeLadderCloseVolume(state,level_state,rules);
      if(close_volume<=0.0)
         continue;
      double target_price=AB_LevelChartPrice(open_price,position_type,
                                            level_state.distance_micro_points,
                                            rules,tick);
      if(target_price<=0.0)
         continue;
      string level_key=object_base+"_L"+IntegerToString(level+1);
      string line_name=level_key+"_LINE";
      string label_name=level_key+"_TEXT";
      AB_AddExpectedVisualizationObject(expected_names,line_name);
      AB_AddExpectedVisualizationObject(expected_names,label_name);
      AB_CreateOrUpdateLevelLine(line_name,target_price,trade_color,line_mode);
      AB_CreateOrUpdatePixelLabel(label_name,
                                  AB_LevelLabelText(alias,level,level_state,close_volume,rules),
                                  target_price,clrWhite,!breakout,selected_ticket==ticket,
                                  label_font_size,placements);
     }
  }

void AB_AddUnmanagedPositionVisualization(const ulong ticket,
                                          const AB_SymbolRules &rules,
                                          const int label_font_size,
                                          const ulong selected_ticket,
                                          string &expected_names[],
                                          AB_ChartLabelPlacement &placements[])
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return;
   ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
      return;
   string name=AB_VisualizationPrefix()+"ORDER_"+IntegerToString((long)ticket)+"_UNMANAGED";
   AB_AddExpectedVisualizationObject(expected_names,name);
   color text_color=position_type==POSITION_TYPE_BUY ? clrLimeGreen : clrTomato;
   AB_CreateOrUpdatePixelLabel(name,"未管理",PositionGetDouble(POSITION_PRICE_OPEN),
                               text_color,true,selected_ticket==ticket,
                               label_font_size,placements);
  }

void AB_RefreshChartVisualization(AB_PositionRegistry &normal_registry,
                                  AB_LadderBook &normal_ladder_book,
                                  AB_BreakoutRegistry &breakout_registry,
                                  AB_LadderBook &breakout_ladder_book,
                                  const AB_LadderConfig &ladder_config,
                                  const AB_BasketSnapshot &long_basket,
                                  const AB_BasketSnapshot &short_basket,
                                  const AB_SymbolRules &rules,
                                  const string symbol,
                                  const long breakout_magic,
                                  const TPLineDisplayMode line_mode,
                                  const int label_font_size,
                                  const ulong selected_ticket)
  {
   string expected_names[];
   ArrayResize(expected_names,0);
   AB_ChartLabelPlacement placements[];
   ArrayResize(placements,0);
   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick))
     {
      AB_DeleteUnexpectedVisualizationObjects(expected_names);
      return;
     }

   int normal_number=0;
   for(int i=0;i<normal_registry.Count();i++)
     {
      AB_PositionLineage lineage;
      if(!normal_registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;
      ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
         continue;
      normal_number++;
      AB_LadderPositionState ladder_state;
      if(!normal_ladder_book.Get(lineage.entity_id,ladder_state))
        {
         ZeroMemory(ladder_state);
         ladder_state.entity_id=lineage.entity_id;
         ladder_state.original_volume=lineage.original_volume;
         ladder_state.current_volume=PositionGetDouble(POSITION_VOLUME);
         AB_LoadLadderLevels(ladder_state.levels,ladder_config.normal);
        }
      bool suppress_ladder=AB_BasketSuspendsNormalLadder(long_basket,
         lineage.position_identifier) ||
         AB_BasketSuspendsNormalLadder(short_basket,
         lineage.position_identifier);
      AB_AddPositionVisualization(lineage.current_ticket,
                                  "普"+IntegerToString(normal_number),
                                  false,ladder_state,ladder_config.normal,
                                  rules,tick,suppress_ladder,line_mode,label_font_size,
                                  selected_ticket,expected_names,placements);
     }

   int breakout_number=0;
   for(int i=0;i<breakout_registry.Count();i++)
     {
      AB_BreakoutLineage lineage;
      if(!breakout_registry.GetAt(i,lineage) || !lineage.managed)
         continue;
      if(!PositionSelectByTicket(lineage.current_ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;
      ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
         continue;
      breakout_number++;
      AB_LadderPositionState ladder_state;
      if(!breakout_ladder_book.Get(lineage.entity_id,ladder_state))
        {
         ZeroMemory(ladder_state);
         ladder_state.entity_id=lineage.entity_id;
         ladder_state.original_volume=lineage.original_volume;
         ladder_state.current_volume=PositionGetDouble(POSITION_VOLUME);
         AB_LoadLadderLevels(ladder_state.levels,ladder_config.breakout);
        }
      AB_AddPositionVisualization(lineage.current_ticket,
                                  "突"+IntegerToString(breakout_number),
                                  true,ladder_state,ladder_config.breakout,
                                  rules,tick,false,line_mode,label_font_size,
                                  selected_ticket,expected_names,placements);
     }

   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;
      ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(position_type!=POSITION_TYPE_BUY && position_type!=POSITION_TYPE_SELL)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)==breakout_magic)
         continue;
      ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      AB_PositionLineage normal_lineage;
      if(normal_registry.GetByPositionIdentifier(position_identifier,normal_lineage) &&
         normal_lineage.managed)
         continue;
      AB_AddUnmanagedPositionVisualization(ticket,rules,label_font_size,
                                           selected_ticket,expected_names,placements);
     }
   AB_DeleteUnexpectedVisualizationObjects(expected_names);
  }

#endif
