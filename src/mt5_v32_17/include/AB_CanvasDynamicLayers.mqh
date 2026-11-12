#ifndef AB_CANVAS_DYNAMIC_LAYERS_MQH
#define AB_CANVAS_DYNAMIC_LAYERS_MQH

#include <Canvas\Canvas.mqh>
#include "AB_CanvasPanel.mqh"
#include "AB_UiRefreshState.mqh"

#define AB_UI_DYNAMIC_HEADER "AB_UI_DYNAMIC_HEADER"
#define AB_UI_DYNAMIC_ORDER  "AB_UI_DYNAMIC_ORDER"
#define AB_UI_DYNAMIC_BASKET "AB_UI_DYNAMIC_BASKET"
#define AB_UI_DYNAMIC_LOG    "AB_UI_DYNAMIC_LOG"

class AB_CanvasDynamicLayers
  {
private:
   long             m_chart_id;
   int              m_panel_x;
   int              m_panel_y;
   int              m_digits;
   AB_PANEL_TAB     m_tab;
   bool             m_collapsed;
   bool             m_created;
   string           m_last_failed_object;
   int              m_last_failed_error;
   CCanvas          m_header_canvas;
   CCanvas          m_order_canvas;
   CCanvas          m_basket_canvas;
   CCanvas          m_log_canvas;
   AB_CanvasPainter m_painter;

   static uint C(const int r,const int g,const int b)
     {
      return XRGB(r,g,b);
     }

   uint TextColor(void) const { return C(248,250,252); }
   uint MutedColor(void) const { return C(139,155,180); }
   uint Surface2Color(void) const { return C(12,16,24); }
   uint BorderStrongColor(void) const { return C(42,54,73); }
   uint PrimaryColor(void) const { return C(104,82,161); }
   uint GreenColor(void) const { return C(107,200,176); }
   uint RedColor(void) const { return C(244,139,139); }

   void Clear(CCanvas &canvas) const
     {
      canvas.Erase(ARGB(0,0,0,0));
     }

   bool CreateLayer(CCanvas &canvas,const string name,const int x,const int y,
                    const int w,const int h)
     {
      if(!canvas.CreateBitmapLabel(m_chart_id,0,name,m_panel_x+x,m_panel_y+y,
                                   w,h,COLOR_FORMAT_ARGB_NORMALIZE))
        {
         m_last_failed_object=name;
         m_last_failed_error=GetLastError();
         return false;
        }
      ObjectSetInteger(m_chart_id,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(m_chart_id,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(m_chart_id,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(m_chart_id,name,OBJPROP_BACK,false);
      ObjectSetInteger(m_chart_id,name,OBJPROP_ZORDER,1001);
      return true;
     }

   void SetVisible(const string name,const bool visible) const
     {
      ObjectSetInteger(m_chart_id,name,OBJPROP_TIMEFRAMES,
                       visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
     }

   void MoveLayer(const string name,const int x,const int y) const
     {
      ObjectSetInteger(m_chart_id,name,OBJPROP_XDISTANCE,m_panel_x+x);
      ObjectSetInteger(m_chart_id,name,OBJPROP_YDISTANCE,m_panel_y+y);
     }

   void Text(CCanvas &canvas,const int x,const int y,const int w,const int h,
             const string value,const int size,const int weight,
             const uint clr,const int align) const
     {
      m_painter.Text(canvas,x,y,w,h,value,size,weight,clr,align);
     }

   int InlineText(CCanvas &canvas,const int x,const int y,const int h,
                  const string value,const int size,const int weight,
                  const uint clr) const
     {
      int width=m_painter.MeasureText(canvas,value,size,weight);
      if(width>0)
         Text(canvas,x,y,width,h,value,size,weight,clr,TA_LEFT);
      return x+width;
     }

   void Box(CCanvas &canvas,const int x,const int y,const int w,const int h,
            const uint fill,const uint border) const
     {
      m_painter.RoundedBox(canvas,x,y,w,h,5,fill,border);
     }

   string Price(const double value) const
     {
      return DoubleToString(value,m_digits);
     }

   void DrawManagementButton(CCanvas &canvas,const int x,const int y,
                             const int w,const int h,const string text,
                             const bool enabled,const uint fill,
                             const uint border,const uint text_color,
                             const uint texture_color) const
     {
      if(enabled)
         m_painter.ButtonRole(canvas,x,y,w,h,text,fill,border,text_color,
                              true,texture_color,FW_SEMIBOLD);
      else
         m_painter.DisabledButton(canvas,x,y,w,h,text,fill,border,text_color);
     }

public:
   AB_CanvasDynamicLayers(void) : m_chart_id(0),m_panel_x(0),m_panel_y(0),
      m_digits(2),m_tab(AB_PANEL_TAB_ORDERS),m_collapsed(false),m_created(false),
      m_last_failed_object(""),m_last_failed_error(0)
     {
     }

   void Configure(const long chart_id,const int panel_x,const int panel_y,
                  const int digits)
     {
      m_chart_id=chart_id;
      m_panel_x=panel_x;
      m_panel_y=panel_y;
      m_digits=MathMax(0,digits);
     }

   void SetOrigin(const int panel_x,const int panel_y)
     {
      m_panel_x=panel_x;
      m_panel_y=panel_y;
     }

   bool Create(void)
     {
      if(m_created)
         return true;
      m_last_failed_object="";
      m_last_failed_error=0;

      // Header: x=16, y=49, w=529, h=31.
      int x=16;
      int y=49;
      int w=529;
      int h=31;
      if(!CreateLayer(m_header_canvas,AB_UI_DYNAMIC_HEADER,x,y,w,h))
         return false;

      // Order: x=31, y=203, w=501, h=166.
      x=31;
      y=203;
      w=501;
      h=166;
      if(!CreateLayer(m_order_canvas,AB_UI_DYNAMIC_ORDER,x,y,w,h))
        {
         m_header_canvas.Destroy();
         return false;
        }

      // Basket: x=31, y=755, w=501, h=125.
      x=31;
      y=755;
      w=501;
      h=125;
      if(!CreateLayer(m_basket_canvas,AB_UI_DYNAMIC_BASKET,x,y,w,h))
        {
         m_order_canvas.Destroy();
         m_header_canvas.Destroy();
         return false;
        }

      int footer=931;
      // Log: x=14, y=footer+39, w=531, h=106.
      x=14;
      y=footer+39;
      w=531;
      h=106;
      if(!CreateLayer(m_log_canvas,AB_UI_DYNAMIC_LOG,x,y,w,h))
        {
         m_basket_canvas.Destroy();
         m_order_canvas.Destroy();
         m_header_canvas.Destroy();
         return false;
        }

      m_created=true;
      SetPage(m_tab,m_collapsed);
      return true;
     }

   void Destroy(void)
     {
      if(!m_created)
         return;
      m_log_canvas.Destroy();
      m_basket_canvas.Destroy();
      m_order_canvas.Destroy();
      m_header_canvas.Destroy();
      m_created=false;
     }

   void Move(void)
     {
      if(!m_created)
         return;
      MoveLayer(AB_UI_DYNAMIC_HEADER,16,49);
      MoveLayer(AB_UI_DYNAMIC_ORDER,31,203);
      MoveLayer(AB_UI_DYNAMIC_BASKET,31,755);
      int footer=931;
      MoveLayer(AB_UI_DYNAMIC_LOG,14,footer+39);
     }

   void SetPage(const AB_PANEL_TAB tab,const bool collapsed)
     {
      m_tab=tab;
      m_collapsed=collapsed;
      if(!m_created)
         return;
      SetVisible(AB_UI_DYNAMIC_HEADER,true);
      SetVisible(AB_UI_DYNAMIC_ORDER,!collapsed && tab==AB_PANEL_TAB_ORDERS);
      SetVisible(AB_UI_DYNAMIC_BASKET,!collapsed && tab==AB_PANEL_TAB_BASKET);
      SetVisible(AB_UI_DYNAMIC_LOG,!collapsed && tab==AB_PANEL_TAB_BASKET);
      Move();
     }

   bool IsLayerObject(const string object_name) const
     {
      return object_name==AB_UI_DYNAMIC_HEADER ||
             object_name==AB_UI_DYNAMIC_ORDER ||
             object_name==AB_UI_DYNAMIC_BASKET ||
             object_name==AB_UI_DYNAMIC_LOG;
     }

   void DrawHeader(const AB_PanelHeaderView &header)
     {
      if(!m_created)
         return;
      Clear(m_header_canvas);
      string managed_counts=IntegerToString(header.managed_buy_count)+"笔多单受管 · "+
                            IntegerToString(header.managed_sell_count)+"笔空单受管";
      string other_counts=IntegerToString(header.breakout_count)+"笔突破单 · "+
                          IntegerToString(header.unmanaged_count)+"笔未受管";
      Text(m_header_canvas,4,3,265,20,managed_counts,16,FW_NORMAL,MutedColor(),TA_LEFT);
      Text(m_header_canvas,284,3,190,20,other_counts,16,FW_NORMAL,MutedColor(),TA_RIGHT);
     }

   void DrawOrder(const AB_PanelPositionView &position)
     {
      if(!m_created)
         return;
      Clear(m_order_canvas);
      string side=position.has_position ? (position.is_buy ? "BUY" : "SELL") : "--";
      uint side_fill=position.has_position ? (position.is_buy ? GreenColor() : RedColor()) : Surface2Color();
      uint side_ink=position.has_position ? (position.is_buy ? C(27,61,43) : C(74,26,36)) : MutedColor();
      string alias=position.has_position && position.alias!="" ? position.alias : "--";
      string ticket=position.has_position ? "#"+IntegerToString((int)position.ticket) : "#--";
      string status=!position.has_position ? "未选择" : (position.managed ? "已管理" : "未管理");
      string volume=position.has_position ? DoubleToString(position.volume,2) : "--";
      string open_price=position.has_position ? Price(position.open_price) : "--";
      string profit=position.has_position
         ? (position.profit>=0.0 ? "+" : "")+DoubleToString(position.profit,2) : "--";
      uint profit_color=position.has_position
         ? (position.profit>=0.0 ? GreenColor() : RedColor()) : TextColor();

      Box(m_order_canvas,0,11,47,27,side_fill,side_fill);
      Text(m_order_canvas,0,11,47,27,side,17,FW_SEMIBOLD,side_ink,TA_CENTER);
      Box(m_order_canvas,54,11,45,27,C(229,221,245),C(229,221,245));
      Text(m_order_canvas,54,11,45,27,alias,17,FW_SEMIBOLD,C(43,35,61),TA_CENTER);
      Text(m_order_canvas,107,11,140,27,ticket,17,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(m_order_canvas,346,11,141,27,status,17,FW_SEMIBOLD,MutedColor(),TA_RIGHT);

      // Fact card backgrounds and labels belong to the static Canvas.  This
      // layer only replaces the values that change with the selected order.
      Text(m_order_canvas,11,73,141,34,volume,20,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(m_order_canvas,180,73,141,34,open_price,20,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(m_order_canvas,349,73,141,34,profit,20,FW_SEMIBOLD,profit_color,TA_LEFT);

      DrawManagementButton(m_order_canvas,1,118,246,47,"加入管理",
                           position.has_position && !position.managed && !position.breakout,
                           C(203,190,234),C(203,190,234),C(45,35,74),C(0,0,0));
      DrawManagementButton(m_order_canvas,254,118,246,47,"退出管理",
                           position.has_position && position.managed && !position.breakout,
                           C(234,201,201),C(234,201,201),C(74,40,40),C(0,0,0));
     }

   void DrawBasket(const AB_PanelBasketView &basket)
     {
      if(!m_created)
         return;
      Clear(m_basket_canvas);
      // Keep each live status fragment on its existing line while allowing the
      // requested size and weight to follow its semantic role.
      int long_x=InlineText(m_basket_canvas,14,5,21,"多单 · ",18,FW_SEMIBOLD,
                            TextColor());
      InlineText(m_basket_canvas,long_x,5,21,
                 basket.long_side.enabled ? basket.long_side.mode_label : "未启用",
                 18,FW_SEMIBOLD,
                 basket.long_side.enabled ? TextColor() : MutedColor());
      int short_x=InlineText(m_basket_canvas,264,5,21,"空单 · ",18,FW_SEMIBOLD,
                             TextColor());
      InlineText(m_basket_canvas,short_x,5,21,
                 basket.short_side.enabled ? basket.short_side.mode_label : "未启用",
                 18,FW_SEMIBOLD,
                 basket.short_side.enabled ? TextColor() : MutedColor());

      if(basket.long_side.enabled)
        {
         long_x=InlineText(m_basket_canvas,14,27,20,
                           IntegerToString(basket.long_side.active_members)+"/"+
                           IntegerToString(basket.long_side.total_members)+" ",
                           18,FW_SEMIBOLD,MutedColor());
         long_x=InlineText(m_basket_canvas,long_x,27,20,basket.long_side.phase_label,
                           18,FW_SEMIBOLD,MutedColor());
         if(basket.long_side.has_trigger_price)
            InlineText(m_basket_canvas,long_x,27,20,
                       " · 触发 "+DoubleToString(basket.long_side.trigger_price,m_digits),
                       18,FW_SEMIBOLD,MutedColor());
        }
      else
         InlineText(m_basket_canvas,14,27,20,"0 笔成员",18,FW_SEMIBOLD,MutedColor());

      if(basket.short_side.enabled)
        {
         short_x=InlineText(m_basket_canvas,264,27,20,
                            IntegerToString(basket.short_side.active_members)+"/"+
                            IntegerToString(basket.short_side.total_members)+" ",
                            18,FW_SEMIBOLD,MutedColor());
         short_x=InlineText(m_basket_canvas,short_x,27,20,basket.short_side.phase_label,
                            18,FW_SEMIBOLD,MutedColor());
         if(basket.short_side.has_trigger_price)
            InlineText(m_basket_canvas,short_x,27,20,
                       " · 触发 "+DoubleToString(basket.short_side.trigger_price,m_digits),
                       18,FW_SEMIBOLD,MutedColor());
        }
      else
         InlineText(m_basket_canvas,264,27,20,"0 笔成员",18,FW_SEMIBOLD,MutedColor());

      string members=basket.active_members>0 ? IntegerToString(basket.active_members)+" 笔" : "--";
      string live_profit=basket.has_live_profit
         ? (basket.live_profit>=0.0 ? "+" : "")+DoubleToString(basket.live_profit,2) : "--";
      uint live_color=!basket.has_live_profit ? TextColor() :
         (basket.live_profit>=0.0 ? GreenColor() : RedColor());
      string zero="--";
      bool both_zero=basket.long_side.has_zero_price && basket.short_side.has_zero_price;
      if(both_zero)
         zero="多 "+Price(basket.long_side.zero_price)+" / 空 "+Price(basket.short_side.zero_price);
      else if(basket.long_side.has_zero_price)
         zero=Price(basket.long_side.zero_price);
      else if(basket.short_side.has_zero_price)
         zero=Price(basket.short_side.zero_price);
      int zero_font_size=18;
      Text(m_basket_canvas,10,88,146,34,members,18,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(m_basket_canvas,185,88,146,34,live_profit,18,FW_SEMIBOLD,live_color,TA_LEFT);
      Text(m_basket_canvas,360,88,117,34,zero,zero_font_size,FW_SEMIBOLD,TextColor(),TA_LEFT);
     }

   void DrawLog(const AB_PanelLogView &log)
     {
      if(!m_created)
         return;
      Clear(m_log_canvas);
      for(int index=0;index<log.count && index<5;index++)
        {
         string row=TimeToString(log.times[index],TIME_SECONDS)+
                    "   ·   "+log.lines[index];
          Text(m_log_canvas,0,index*21,530,20,row,18,FW_NORMAL,
              C(185,192,188),TA_LEFT);
        }
     }

   string LastFailedObject(void) const { return m_last_failed_object; }
   int LastFailedError(void) const { return m_last_failed_error; }

   void UploadDirty(const uint flags)
     {
      if(!m_created)
         return;
      if((flags&AB_UI_DIRTY_HEADER)!=0)
         m_header_canvas.Update(false);
      if((flags&AB_UI_DIRTY_ORDER)!=0)
         m_order_canvas.Update(false);
      if((flags&AB_UI_DIRTY_BASKET)!=0)
         m_basket_canvas.Update(false);
      if((flags&AB_UI_DIRTY_LOG)!=0)
         m_log_canvas.Update(false);
     }
  };

#endif
