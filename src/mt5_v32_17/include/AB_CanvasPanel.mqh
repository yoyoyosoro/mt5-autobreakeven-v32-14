#ifndef AB_CANVAS_PANEL_MQH
#define AB_CANVAS_PANEL_MQH

#include <Canvas\Canvas.mqh>
#include "AB_CommandQuery.mqh"
#include "AB_CanvasPainter.mqh"

#define AB_UI_PANEL_WIDTH    563
#define AB_UI_ORDERS_HEIGHT  1255
#define AB_UI_BASKET_HEIGHT  1255
#define AB_UI_COLLAPSED_HEIGHT  95
#define AB_UI_PANEL_X        10
#define AB_UI_PANEL_Y        120
#define AB_UI_COLLAPSE_X     519
#define AB_UI_COLLAPSE_Y     10
#define AB_UI_COLLAPSE_SIZE  33

// The panel is a rendering surface only.  Trading commands remain in the
// runtime module and are intentionally not implemented here.
enum AB_PANEL_TAB
  {
   AB_PANEL_TAB_ORDERS = 0,
   AB_PANEL_TAB_BASKET = 1
  };

enum AB_PANEL_ACTION
  {
   AB_PANEL_ACTION_NONE = 0,
   AB_PANEL_ACTION_JOIN_MANAGEMENT,
   AB_PANEL_ACTION_EXIT_MANAGEMENT,
   AB_PANEL_ACTION_SL_M1,
   AB_PANEL_ACTION_SL_ENTRY,
   AB_PANEL_ACTION_AUTO_MODE_M1,
   AB_PANEL_ACTION_AUTO_MODE_ENTRY,
   AB_PANEL_ACTION_AUTO_MODE_OFF,
   AB_PANEL_ACTION_TOGGLE_LADDER,
   AB_PANEL_ACTION_TRAIL_1,
   AB_PANEL_ACTION_TRAIL_2,
   AB_PANEL_ACTION_TRAIL_3,
   AB_PANEL_ACTION_TRAIL_4,
   AB_PANEL_ACTION_STOP_TRAILING,
   AB_PANEL_ACTION_CLOSE_5,
   AB_PANEL_ACTION_CLOSE_10,
   AB_PANEL_ACTION_CLOSE_25,
   AB_PANEL_ACTION_CLOSE_50,
   AB_PANEL_ACTION_CLOSE_ALL,
   AB_PANEL_ACTION_TRIGGER_NEXT_LEVEL,
   AB_PANEL_ACTION_BASKET_LONG,
   AB_PANEL_ACTION_BASKET_SHORT,
   AB_PANEL_ACTION_BASKET_LONG_NO_LADDER,
   AB_PANEL_ACTION_BASKET_SHORT_NO_LADDER,
   AB_PANEL_ACTION_BASKET_CANCEL,
   AB_PANEL_ACTION_BASKET_MODE_TP,
   AB_PANEL_ACTION_BASKET_MODE_TRAILING,
   AB_PANEL_ACTION_BASKET_MODE_ONE_SHOT_SL,
   AB_PANEL_ACTION_STRADDLE_START,
   AB_PANEL_ACTION_STRADDLE_CANCEL,
   AB_PANEL_ACTION_CLEAR_LOG,
   AB_PANEL_ACTION_STRADDLE_SETTLE
  };

enum TPLineDisplayMode
  {
   TP_LINE_SHORT = 0, // 短线
   TP_LINE_FULL = 1,  // 全图线
   TP_LINE_OFF = 2    // 关闭
  };

enum PanelAnchor
  {
   PANEL_TOP_LEFT = 0,     // 左上角
   PANEL_TOP_RIGHT = 1,    // 右上角
   PANEL_BOTTOM_LEFT = 2,  // 左下角
   PANEL_BOTTOM_RIGHT = 3  // 右下角
  };

enum PanelRedGreenMode
  {
   PANEL_GREEN_UP = 0, // 绿涨红跌
   PANEL_RED_UP = 1    // 红涨绿跌
  };

struct AB_CanvasPanelConfig
  {
   PanelAnchor anchor;
   int panel_x;
   int panel_y;
   int panel_width;
   int panel_height;
   int page_vertical_spacing;
   int function_button_height;
   int tp_label_font_size;
   int log_history;
   PanelRedGreenMode red_green_mode;
   TPLineDisplayMode tp_line_display_mode;
   int trail_1;
   int trail_2;
   int trail_3;
   int trail_4;
   double close_1;
   double close_2;
   double close_3;
   double close_4;
   int basket_mode;
   int basket_trailing;
   int basket_reverse_close;
   int auto_mode;
   bool ladder_enabled;
  };

struct AB_PanelPositionView
  {
   bool has_position;
   bool is_buy;
   ulong ticket;
   double volume;
   double open_price;
   double profit;
   AB_ManagedEntityId entity_id;
   bool managed;
   bool selected;
   bool breakout;
   string alias;
  };

struct AB_PanelHeaderView
  {
   int managed_buy_count;
   int managed_sell_count;
   int breakout_count;
   int unmanaged_count;
  };

struct AB_PanelBasketSideView
  {
   bool enabled;
   string mode_label;
   string phase_label;
   int active_members;
   int total_members;
   bool has_trigger_price;
   double trigger_price;
   bool has_zero_price;
   double zero_price;
   double live_profit;
  };

struct AB_PanelBasketView
  {
   AB_PanelBasketSideView long_side;
   AB_PanelBasketSideView short_side;
   int active_members;
   bool has_live_profit;
   double live_profit;
  };

struct AB_PanelLogView
  {
   int count;
   datetime times[5];
   string lines[5];
  };

class AB_CanvasPanel
  {
private:
   long          m_chart_id;
   string        m_name;
   CCanvas       m_canvas;
   AB_PANEL_TAB  m_tab;
   bool          m_created;
   bool          m_collapsed;
   string        m_last_failed_object;
   int           m_last_failed_error;
   int           m_width;
   int           m_height;
   AB_CanvasPanelConfig m_config;
   AB_CanvasPainter m_painter;

   static uint C(const int r,const int g,const int b)
     {
      return XRGB(r,g,b);
     }

   void SetDefaultConfig(void)
     {
      m_config.anchor=PANEL_TOP_LEFT;
      m_config.panel_x=AB_UI_PANEL_X;
      m_config.panel_y=AB_UI_PANEL_Y;
      m_config.panel_width=AB_UI_PANEL_WIDTH;
      m_config.panel_height=AB_UI_ORDERS_HEIGHT;
      m_config.page_vertical_spacing=24;
      m_config.function_button_height=36;
      m_config.tp_label_font_size=8;
      m_config.log_history=7;
      m_config.red_green_mode=PANEL_GREEN_UP;
      m_config.tp_line_display_mode=TP_LINE_SHORT;
      m_config.trail_1=50;
      m_config.trail_2=100;
      m_config.trail_3=200;
      m_config.trail_4=300;
      m_config.close_1=5.0;
      m_config.close_2=10.0;
      m_config.close_3=25.0;
      m_config.close_4=50.0;
      m_config.basket_mode=0;
      m_config.basket_trailing=100;
      m_config.basket_reverse_close=100;
      m_config.auto_mode=0;
      m_config.ladder_enabled=true;
     }

   void NormalizeConfig(void)
     {
      m_config.panel_x=MathMax(0,m_config.panel_x);
      m_config.panel_y=MathMax(0,m_config.panel_y);
      m_config.panel_width=AB_UI_PANEL_WIDTH;
      m_config.panel_height=MathMax(420,m_config.panel_height);
      m_config.page_vertical_spacing=MathMax(0,MathMin(40,m_config.page_vertical_spacing));
      m_config.function_button_height=MathMax(24,MathMin(48,m_config.function_button_height));
      m_config.tp_label_font_size=MathMax(6,MathMin(14,m_config.tp_label_font_size));
      m_config.log_history=MathMax(1,MathMin(20,m_config.log_history));
      m_config.trail_1=MathMax(1,m_config.trail_1);
      m_config.trail_2=MathMax(1,m_config.trail_2);
      m_config.trail_3=MathMax(1,m_config.trail_3);
      m_config.trail_4=MathMax(1,m_config.trail_4);
      m_config.close_1=MathMax(0.0,MathMin(100.0,m_config.close_1));
      m_config.close_2=MathMax(0.0,MathMin(100.0,m_config.close_2));
      m_config.close_3=MathMax(0.0,MathMin(100.0,m_config.close_3));
      m_config.close_4=MathMax(0.0,MathMin(100.0,m_config.close_4));
      m_config.basket_trailing=MathMax(0,m_config.basket_trailing);
      m_config.basket_reverse_close=MathMax(0,m_config.basket_reverse_close);
     }

   int PanelX(void) const
     {
      int offset=MathMax(0,m_config.panel_x);
      if(m_config.anchor==PANEL_TOP_LEFT || m_config.anchor==PANEL_BOTTOM_LEFT)
         return offset;
      long chart_width=ChartGetInteger(m_chart_id,CHART_WIDTH_IN_PIXELS);
      if(chart_width<=0)
         chart_width=m_width+offset;
      return MathMax(0,(int)chart_width-m_width-offset);
     }

   int PanelY(void) const
     {
      int offset=MathMax(0,m_config.panel_y);
      if(m_config.anchor==PANEL_TOP_LEFT || m_config.anchor==PANEL_TOP_RIGHT)
         return offset;
      long chart_height=ChartGetInteger(m_chart_id,CHART_HEIGHT_IN_PIXELS);
      if(chart_height<=0)
         chart_height=m_height+offset;
      return MathMax(0,(int)chart_height-m_height-offset);
     }

   string PercentText(const double value) const
     {
      string text=DoubleToString(value,8);
      while(StringLen(text)>0 && StringSubstr(text,StringLen(text)-1,1)=="0")
         text=StringSubstr(text,0,StringLen(text)-1);
      if(StringLen(text)>0 && StringSubstr(text,StringLen(text)-1,1)==".")
         text=StringSubstr(text,0,StringLen(text)-1);
      return text+"%";
     }

   uint PageColor(void) const { return C(7,10,17); }
   uint PanelColor(void) const { return C(10,13,20); }
   uint SurfaceColor(void) const { return C(18,21,31); }
   uint Surface2Color(void) const { return C(12,16,24); }
   uint BorderColor(void) const { return C(34,43,59); }
   uint BorderStrongColor(void) const { return C(42,54,73); }
   uint TextColor(void) const { return C(248,250,252); }
   uint MutedColor(void) const { return C(139,155,180); }
   uint Muted2Color(void) const { return C(104,120,145); }
   uint PurpleColor(void) const { return C(174,155,245); }
   uint PrimaryColor(void) const { return C(104,82,161); }
   uint PinkColor(void) const { return C(250,214,219); }
   uint GreenColor(void) const { return C(107,200,176); }
   uint RedColor(void) const { return C(244,139,139); }
   uint YellowColor(void) const { return C(214,168,106); }
   uint ButtonInk(void) const { return C(27,32,48); }

   uint Blend(const uint base,const uint overlay,const int alpha) const
     {
      int a=MathMax(0,MathMin(255,alpha));
      int inv=255-a;
      int r=((int)GETRGBR(base)*inv+(int)GETRGBR(overlay)*a+127)/255;
      int g=((int)GETRGBG(base)*inv+(int)GETRGBG(overlay)*a+127)/255;
      int b=((int)GETRGBB(base)*inv+(int)GETRGBB(overlay)*a+127)/255;
      return C(r,g,b);
     }

   uint TextureLine(const uint fill,const uint requested) const
     {
      // The HTML uses rgba(255,255,255,.06) for light textures and
      // rgba(0,0,0,.04) for dark textures.  CCanvas stores opaque pixels,
      // so pre-composite those two overlays before drawing the 1px line.
      if(requested==C(255,255,255))
         return Blend(fill,C(255,255,255),15);
      if(requested==C(0,0,0))
         return Blend(fill,C(0,0,0),10);
      return requested;
     }

   string LatinFontFace(const uint role) const
     {
      if(role==FW_NORMAL)
         return "::resources\\fonts\\Inter-Regular.ttf";
      if(role==FW_MEDIUM)
         return "::resources\\fonts\\Inter-Medium.ttf";
      return "::resources\\fonts\\Inter-SemiBold.ttf";
     }

   string DigitFontFace(const uint role) const
     {
      return LatinFontFace(role);
     }

   string InterFontFamily(const uint role) const
     {
      if(role==FW_NORMAL)
         return "Inter";
      if(role==FW_MEDIUM)
         return "Inter Medium";
      // The HTML only loads Inter through 600. Its computed 700 roles use
      // the nearest available Inter face, which is SemiBold.
      return "Inter SemiBold";
     }

   int FontPx(const int px) const
     {
      if(px<=11)
         return px+6;
      if(px<=12)
         return px+5;
      return px+4;
     }

   bool SetLatinFont(const int px,const uint role)
     {
      // Loading the TTF registers the internal family. Drawing by the
      // resource path itself falls back in MT5, so select the family next.
      m_canvas.FontSet(LatinFontFace(role),px,FW_NORMAL);
      if(m_canvas.FontSet(InterFontFamily(role),px,FW_NORMAL))
         return true;
      return m_canvas.FontSet("Arial",px,role);
     }

   bool SetDigitFont(const int px,const uint role)
     {
      return SetLatinFont(px,role);
     }

   bool SetCjkFont(const int px,const uint role)
     {
      // MT5 reliably distinguishes the installed Noto family at 400 and 600.
      // HTML's intermediate 500 role is intentionally mapped to regular.
      const uint cjk_role=(role==FW_NORMAL)
                          ? FW_NORMAL
                          : (role==FW_MEDIUM ? FW_MEDIUM : FW_SEMIBOLD);
      if(m_canvas.FontSet("Noto Sans SC",px,cjk_role))
         return true;
      return m_canvas.FontSet("Microsoft YaHei UI",px,cjk_role);
     }

   int TextRunKind(const ushort code) const
     {
      if((code>=48 && code<=57) || code==35 || code==37 || code==43 ||
         code==44 || code==45 || code==46 || code==47 || code==58)
         return 2;
      if(code>=32 && code<=126)
         return 1;
      return 0;
     }

   int RunWidth(const string value,const int px,const uint role,const int kind)
     {
      if(kind==2)
        {
         if(!SetDigitFont(px,role))
            return 0;
        }
      else if(kind==1)
        {
         if(!SetLatinFont(px,role))
            return 0;
        }
      else
        {
         if(!SetCjkFont(px,role))
            return 0;
        }
      return m_canvas.TextWidth(value);
     }

   int MixedTextWidth(const string value,const int px,const uint role)
     {
      if(StringLen(value)<=0)
         return 0;
      int total=0;
      int len=StringLen(value);
      int start=0;
      int kind=TextRunKind((ushort)StringGetCharacter(value,0));
      for(int i=1;i<len;i++)
        {
         int now_kind=TextRunKind((ushort)StringGetCharacter(value,i));
         if(now_kind==kind)
            continue;
         total+=RunWidth(StringSubstr(value,start,i-start),px,role,kind);
         start=i;
         kind=now_kind;
        }
      total+=RunWidth(StringSubstr(value,start),px,role,kind);
      return total;
     }

   int MixedTextHeight(const int px,const uint role)
     {
      int h=0;
      if(SetLatinFont(px,role))
         h=(int)MathMax(h,m_canvas.TextHeight("Ag"));
      if(SetDigitFont(px,role))
         h=(int)MathMax(h,m_canvas.TextHeight("0123456789"));
      if(SetCjkFont(px,role))
         h=(int)MathMax(h,m_canvas.TextHeight("自动"));
      return h;
     }

   void FillRoundedAA(const int x,const int y,const int w,const int h,
                      const int radius,const uint fill)
     {
      if(w<=0 || h<=0)
         return;
      int limit=(int)MathMin(w,h)/2;
      int r=radius;
      if(r<1)
         r=1;
      if(r>limit)
         r=limit;

      // Match the proven MT4 Canvas construction: opaque spans and circles
      // form the body; RoundedBox adds the antialiased perimeter afterward.
      m_canvas.FillRectangle(x+r,y,x+w-r-1,y+h-1,fill);
      m_canvas.FillRectangle(x,y+r,x+w-1,y+h-r-1,fill);
      m_canvas.FillCircle(x+r,y+r,r,fill);
      m_canvas.FillCircle(x+w-r-1,y+r,r,fill);
      m_canvas.FillCircle(x+r,y+h-r-1,r,fill);
      m_canvas.FillCircle(x+w-r-1,y+h-r-1,r,fill);
     }

   void RoundedQuarterArcAA(const int center_x,const int center_y,
                            const int radius,const double start_angle,
                            const uint clr)
     {
      int segments=(int)MathMax(12,radius*4);
      double step=(3.14159265358979323846*0.5)/(double)segments;
      for(int i=0;i<=segments;i++)
        {
         double angle=start_angle+step*i;
         m_canvas.PixelSetAA((double)center_x+(double)radius*MathCos(angle),
                             (double)center_y+(double)radius*MathSin(angle),
                             clr);
        }
     }

   void RoundedBox(const int x,const int y,const int w,const int h,
                   const int radius,const uint fill,const uint border)
     {
      m_painter.RoundedBox(m_canvas,x,y,w,h,radius,fill,border);
     }

   void DrawOuterBorder(void)
     {
      const int radius=6;
      uint outside=PageColor();
      uint border=BorderStrongColor();
      for(int y=0;y<radius;y++)
        {
         for(int x=0;x<radius;x++)
           {
            double dx=(double)(radius-x);
            double dy=(double)(radius-y);
            if(dx*dx+dy*dy<=(double)(radius*radius))
               continue;
            m_canvas.PixelSet(x,y,outside);
            m_canvas.PixelSet(m_width-x-1,y,outside);
            m_canvas.PixelSet(x,m_height-y-1,outside);
            m_canvas.PixelSet(m_width-x-1,m_height-y-1,outside);
           }
        }
      m_canvas.LineAA(radius,0,m_width-radius-1,0,border);
      m_canvas.LineAA(m_width-1,radius,m_width-1,m_height-radius-1,border);
      m_canvas.LineAA(m_width-radius-1,m_height-1,radius,m_height-1,border);
      m_canvas.LineAA(0,m_height-radius-1,0,radius,border);
      RoundedQuarterArcAA(radius,radius,radius,3.14159265358979323846,border);
      RoundedQuarterArcAA(m_width-radius-1,radius,radius,
                          3.14159265358979323846*1.5,border);
      RoundedQuarterArcAA(m_width-radius-1,m_height-radius-1,radius,0.0,border);
      RoundedQuarterArcAA(radius,m_height-radius-1,radius,
                          3.14159265358979323846*0.5,border);
     }

   void DiagonalTexture(const int x,const int y,const int w,const int h,
                        const uint line_color,const int radius)
     {
      if(w<=0 || h<=0)
         return;
      // Keep the texture away from the rounded perimeter, as in the MT4
      // renderer.  This prevents an opaque stripe pixel from replacing an
      // antialiased corner pixel.
      int inset=(int)MathMax(3,radius-1);
      int left=x+inset;
      int top=y+inset;
      int right=x+w-inset;
      int bottom=y+h-inset;
      int inner_height=bottom-top;
      if(right<left || bottom<top || inner_height<=0)
         return;
      for(int offset=-inner_height;offset<=right-left;offset+=6)
        {
         int x1=left+offset;
         int y1=bottom;
         int x2=x1+inner_height;
         int y2=top;
         if(x1<left)
           {
            y1-=left-x1;
            x1=left;
           }
         if(x2>right)
           {
            y2+=x2-right;
            x2=right;
           }
         if(x1>right || x2<left || y1<top || y2>bottom)
            continue;
         m_canvas.Line(x1,y1,x2,y2,line_color);
        }
     }

   void Text(const int x,const int y,const int w,const int h,
             const string value,const int px,const uint role,
             const uint clr,const int align_mode)
     {
      m_painter.Text(m_canvas,x,y,w,h,value,px,(int)role,clr,align_mode);
     }

   void ButtonRole(const int x,const int y,const int w,const int h,
                    const string label,const uint fill,const uint border,
                    const uint text_color,const bool texture,
                    const uint texture_color,const uint role,
                    const int text_size=18)
     {
      RoundedBox(x,y,w,h,5,fill,border);
      if(texture)
         DiagonalTexture(x,y,w,h,
                         TextureLine(fill,texture_color==0 ? C(255,255,255) : texture_color),4);
      Text(x,y,w,h,label,text_size,role,text_color,TA_CENTER);
     }

   void Button(const int x,const int y,const int w,const int h,
               const string label,const uint fill,const uint border,
               const uint text_color,const bool texture,
               const uint texture_color)
     {
      ButtonRole(x,y,w,h,label,fill,border,text_color,texture,texture_color,FW_SEMIBOLD);
     }

   void StrongButton(const int x,const int y,const int w,const int h,
                     const string label,const uint fill,const uint border,
                     const uint text_color,const bool texture,
                     const uint texture_color,const int text_size=18)
     {
      // HTML order emphasis and selected command variants use 600.
      ButtonRole(x,y,w,h,label,fill,border,text_color,texture,texture_color,
                 FW_SEMIBOLD,text_size);
     }

   void DisabledButton(const int x,const int y,const int w,const int h,
                       const string label,const uint fill,const uint border,
                       const uint text_color)
     {
      // button:disabled applies opacity:.38 to the complete HTML element.
      uint disabled_fill=Blend(SurfaceColor(),fill,97);
      uint disabled_border=Blend(SurfaceColor(),border,97);
      uint disabled_text=Blend(SurfaceColor(),text_color,97);
      StrongButton(x,y,w,h,label,disabled_fill,disabled_border,disabled_text,true,C(0,0,0));
     }

   void Heading(const int x,const int y,const int w,const string title,
                const string note)
     {
      Text(x,y,w-190,27,title,19,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(x+190,y,w-204,27,note,18,FW_NORMAL,MutedColor(),TA_RIGHT);
     }

   void OrderHeading(const int x,const int y,const int w,const string title,
                     const string note)
     {
      Text(x,y,w-190,27,title,19,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(x+190,y,w-190,27,note,18,FW_NORMAL,MutedColor(),TA_RIGHT);
     }

   void Card(const int x,const int y,const int w,const int h)
     {
      RoundedBox(x,y,w,h,9,SurfaceColor(),BorderColor());
     }

   void Tag(const int x,const int y,const int w,const int h,const string label,
            const uint fill,const uint ink)
     {
      RoundedBox(x,y,w,h,5,fill,fill);
      Text(x,y,w,h,label,14,FW_SEMIBOLD,ink,TA_CENTER);
     }

   void Fact(const int x,const int y,const int w,const int h,
             const string label,const string value,const uint value_color,
              const int value_px=15,const int label_px=15,
              const uint label_role=FW_NORMAL)
     {
      RoundedBox(x,y,w,h,5,Surface2Color(),C(34,38,36));
      Text(x+10,y+5,w-20,18,label,label_px,label_role,MutedColor(),TA_LEFT);
      Text(x+10,y+23,w-20,h-25,value,value_px,FW_SEMIBOLD,value_color,TA_LEFT);
     }

   void Switch(const int x,const int y,const bool on=true)
     {
      RoundedBox(x,y,43,25,13,on ? PurpleColor() : Surface2Color(),
                 on ? PurpleColor() : BorderColor());
      m_canvas.FillCircle(on ? x+31 : x+12,y+12,8,C(255,255,255));
     }

   void DrawStaticHeader(void)
     {
      m_canvas.FillRectangle(0,0,m_width,m_height,PanelColor());
      m_canvas.LineHorizontal(1,m_width-2,92,BorderColor());
      const int title_x=20;
      const int title_y=12;
      const int title_h=30;
      const int badge_h=27;
      string title="自动保本 v"+AB_EA_VERSION;
      int title_width=MixedTextWidth(title,FontPx(25),FW_SEMIBOLD);
      int badge_x=title_x+title_width+10;
      int badge_y=title_y+(title_h-badge_h+1)/2;
      Text(title_x,title_y,title_width,title_h,title,25,FW_SEMIBOLD,TextColor(),TA_LEFT);
      RoundedBox(badge_x,badge_y,75,badge_h,6,C(35,28,70),C(104,82,161));
      m_canvas.FillCircle(badge_x+13,badge_y+13,3,PurpleColor());
      Text(badge_x+20,badge_y,52,badge_h,"运行中",16,FW_MEDIUM,PurpleColor(),TA_LEFT);
      RoundedBox(AB_UI_COLLAPSE_X,AB_UI_COLLAPSE_Y,
                 AB_UI_COLLAPSE_SIZE,AB_UI_COLLAPSE_SIZE,
                 9,SurfaceColor(),BorderColor());
      if(m_collapsed)
         DrawExpandChevron();
      else
         Text(AB_UI_COLLAPSE_X,AB_UI_COLLAPSE_Y,
              AB_UI_COLLAPSE_SIZE,AB_UI_COLLAPSE_SIZE,
              "−",20,FW_SEMIBOLD,MutedColor(),TA_CENTER);
     }

   void DrawExpandChevron(void)
     {
      uint chevron_color=MutedColor();
      m_canvas.LineAA(AB_UI_COLLAPSE_X+9,AB_UI_COLLAPSE_Y+12,
                      AB_UI_COLLAPSE_X+16,AB_UI_COLLAPSE_Y+19,chevron_color);
      m_canvas.LineAA(AB_UI_COLLAPSE_X+10,AB_UI_COLLAPSE_Y+12,
                      AB_UI_COLLAPSE_X+16,AB_UI_COLLAPSE_Y+18,chevron_color);
      m_canvas.LineAA(AB_UI_COLLAPSE_X+16,AB_UI_COLLAPSE_Y+19,
                      AB_UI_COLLAPSE_X+23,AB_UI_COLLAPSE_Y+12,chevron_color);
      m_canvas.LineAA(AB_UI_COLLAPSE_X+16,AB_UI_COLLAPSE_Y+18,
                      AB_UI_COLLAPSE_X+22,AB_UI_COLLAPSE_Y+12,chevron_color);
     }

   void DrawTabs(void)
     {
      m_canvas.LineHorizontal(17,546,148,BorderColor());
      string labels[2] = {"订单操作","组合保本"};
      const int tab_left=17;
      const int tab_right=546;
      const int tab_width=(tab_right-tab_left)/2;
      for(int i=0;i<2;i++)
        {
         int x=tab_left+i*tab_width;
         int width=(i==0 ? tab_width : tab_right-x);
         Text(x,106,width,42,labels[i],18,FW_SEMIBOLD,
              i==(int)m_tab ? TextColor() : MutedColor(),TA_CENTER);
         if(i==(int)m_tab)
            m_canvas.FillRectangle(x,146,x+width-1,148,PurpleColor());
        }
     }

   void ButtonShell(const int x,const int y,const int w,const int h,
                    const uint fill,const uint border)
     {
      RoundedBox(x,y,w,h,5,fill,border);
     }

   void TagShell(const int x,const int y,const int w,const int h,
                 const uint fill,const uint border)
     {
      RoundedBox(x,y,w,h,5,fill,border);
     }

   void FactShell(const int x,const int y,const int w,const int h,
                  const string label)
     {
      RoundedBox(x,y,w,h,5,Surface2Color(),C(34,38,36));
      Text(x+10,y+5,w-20,18,label,12,FW_NORMAL,MutedColor(),TA_LEFT);
     }

   void StatusShell(const int x,const int y,const int w,const int h,
                    const uint accent)
     {
      m_canvas.FillRectangle(x,y,x+3,y+h,accent);
      RoundedBox(x+3,y,w-3,h,5,Surface2Color(),Surface2Color());
     }

   void DrawStaticOrders(void)
     {
      const int x=17;
      const int w=529;
      Card(x,159,w,222);
      OrderHeading(x+15,171,w-30,"当前选择","图表单选");
      TagShell(x+14,214,47,27,Surface2Color(),Surface2Color());
      TagShell(x+68,214,45,27,C(229,221,245),C(229,221,245));
      Fact(x+15,253,161,59,"当前手数","",TextColor());
      Fact(x+184,253,161,59,"开仓价","",TextColor());
      Fact(x+353,253,161,59,"当前盈亏","",TextColor());
      ButtonShell(x+15,321,246,47,Surface2Color(),BorderStrongColor());
      ButtonShell(x+268,321,246,47,Surface2Color(),BorderStrongColor());

      Card(x,395,w,164);
      OrderHeading(x+15,407,w-30,"自动管理","作用于受管订单");
      bool auto_m1=m_config.auto_mode==0;
      bool auto_entry=m_config.auto_mode==1;
      bool auto_off=m_config.auto_mode==2;
      Button(x+15,450,161,47,"M1极值止损",auto_m1 ? PrimaryColor() : Surface2Color(),auto_m1 ? PrimaryColor() : BorderStrongColor(),TextColor(),auto_m1,C(113,92,167));
      Button(x+184,450,161,47,"开仓价止损",auto_entry ? PrimaryColor() : Surface2Color(),auto_entry ? PrimaryColor() : BorderStrongColor(),TextColor(),auto_entry,C(113,92,167));
      Button(x+353,450,161,47,"关闭",auto_off ? PrimaryColor() : Surface2Color(),auto_off ? PrimaryColor() : BorderStrongColor(),TextColor(),auto_off,C(113,92,167));
      Text(x+15,505,330,22,"阶梯止盈",17,FW_SEMIBOLD,TextColor(),TA_LEFT);
      Text(x+15,526,390,18,"恢复时按当前价格判断未完成档位",15,FW_NORMAL,MutedColor(),TA_LEFT);
      Switch(x+456,507,m_config.ladder_enabled);

      Card(x,572,w,115);
      OrderHeading(x+15,584,w-30,"手动设定止损","无选择时处理最新原始订单");
      Button(x+15,627,246,47,"M1极值止损",PurpleColor(),PurpleColor(),C(41,22,102),true,C(0,0,0));
      Button(x+268,627,246,47,"开仓价止损",C(229,221,245),C(229,221,245),C(43,35,61),true,C(0,0,0));

      Card(x,700,w,170);
      OrderHeading(x+15,712,w-30,"追踪止损","点击即执行 · 四档可配置");
      // HTML quick-grid and width:100% buttons share the same card content box.
      Button(x+15,755,119,47,IntegerToString(m_config.trail_1),C(126,87,194),C(126,87,194),TextColor(),true,C(255,255,255));
      Button(x+142,755,119,47,IntegerToString(m_config.trail_2),C(134,79,192),C(134,79,192),TextColor(),true,C(255,255,255));
      Button(x+268,755,119,47,IntegerToString(m_config.trail_3),C(142,72,189),C(142,72,189),TextColor(),true,C(255,255,255));
      Button(x+395,755,119,47,IntegerToString(m_config.trail_4),C(150,64,185),C(150,64,185),TextColor(),true,C(255,255,255));
      Button(x+15,809,499,47,"停止追踪",Surface2Color(),BorderStrongColor(),TextColor(),false,C(0,0,0));

      Card(x,883,w,225);
      OrderHeading(x+15,895,w-30,"手动平仓","点击即执行 · 按原始仓位计算");
      Button(x+15,938,119,47,PercentText(m_config.close_1),C(126,87,194),C(126,87,194),TextColor(),true,C(255,255,255));
      Button(x+142,938,119,47,PercentText(m_config.close_2),C(134,79,192),C(134,79,192),TextColor(),true,C(255,255,255));
      Button(x+268,938,119,47,PercentText(m_config.close_3),C(142,72,189),C(142,72,189),TextColor(),true,C(255,255,255));
      Button(x+395,938,119,47,PercentText(m_config.close_4),C(150,64,185),C(150,64,185),TextColor(),true,C(255,255,255));
       StrongButton(x+15,992,499,47,"整单平仓",PinkColor(),PinkColor(),C(74,27,39),true,C(0,0,0));
      Button(x+15,1046,499,47,"触发下一阶止盈",PurpleColor(),PurpleColor(),C(41,22,102),true,C(0,0,0));
     }

   void DrawStaticBasket(void)
     {
      const int x=17;
      const int w=529;
      Card(x,159,w,115);
      Heading(x+14,171,w-28,"选择保本止盈模式","到价由 broker 平仓");
      bool tp_mode=m_config.basket_mode==0;
      bool trailing_mode=m_config.basket_mode==1;
      bool one_shot_mode=m_config.basket_mode==2;
      Button(x+15,214,161,47,"保本 TP",
             tp_mode ? PrimaryColor() : Surface2Color(),
             tp_mode ? PrimaryColor() : BorderStrongColor(),TextColor(),tp_mode,C(113,92,167));
      Button(x+184,214,161,47,"追踪止损",
             trailing_mode ? PrimaryColor() : Surface2Color(),
             trailing_mode ? PrimaryColor() : BorderStrongColor(),TextColor(),trailing_mode,C(113,92,167));
      Button(x+353,214,161,47,"单次保本 SL",
             one_shot_mode ? PrimaryColor() : Surface2Color(),
             one_shot_mode ? PrimaryColor() : BorderStrongColor(),TextColor(),one_shot_mode,C(113,92,167));

      Card(x,287,w,162);
      Heading(x+14,299,w-28,"模式参数","按模式启用");
       Text(x+14,343,108,38,"追踪止损距离",18,FW_NORMAL,MutedColor(),TA_LEFT);
      ReadOnlyParameterField(x+132,343,369,38,IntegerToString(m_config.basket_trailing),"微点");
       Text(x+14,389,108,38,"反向强平距离",18,FW_NORMAL,MutedColor(),TA_LEFT);
      ReadOnlyParameterField(x+132,389,369,38,IntegerToString(m_config.basket_reverse_close),"微点");

      Card(x,462,w,225);
      Heading(x+14,474,w-28,"组合保本止盈","当前品种 · 受管订单");
      StrongButton(x+15,517,246,47,"多单组合保本挂TP",C(124,191,158),C(124,191,158),C(27,61,43),true,C(117,180,149));
      StrongButton(x+268,517,246,47,"空单组合保本挂TP",C(224,122,138),C(224,122,138),C(74,26,36),true,C(211,115,130));
      StrongButton(x+15,571,246,47,"多单无阶梯组合保本",C(124,191,158),C(124,191,158),C(27,61,43),true,C(117,180,149));
      StrongButton(x+268,571,246,47,"空单无阶梯组合保本",C(224,122,138),C(224,122,138),C(74,26,36),true,C(211,115,130));
      Button(x+15,625,499,47,"取消组合保本止盈",PrimaryColor(),PrimaryColor(),TextColor(),true,C(113,92,167));

      Card(x,700,w,200);
      Heading(x+14,712,w-28,"组合状态","冻结后不自动重算");
      StatusShell(x+14,755,243,54,GreenColor());
      StatusShell(x+264,755,237,54,RedColor());
       Fact(x+14,820,166,59,"组合成员","",TextColor(),18,18,FW_SEMIBOLD);
       Fact(x+189,820,166,59,"当前净值","",TextColor(),18,18,FW_SEMIBOLD);
       Fact(x+364,820,137,59,"归零价","",TextColor(),18,18,FW_SEMIBOLD);
     }

   void ReadOnlyParameterField(const int x,const int y,const int w,const int h,
                               const string value,const string unit)
     {
      RoundedBox(x,y,w,h,6,Surface2Color(),BorderStrongColor());
       Text(x+12,y,w-55,h,value,18,FW_SEMIBOLD,TextColor(),TA_LEFT);
       if(unit!="")
          Text(x+w-45,y,35,h,unit,18,FW_NORMAL,MutedColor(),TA_RIGHT);
     }

   void DrawBreakout(void)
     {
      Card(17,1122,529,121);
      OrderHeading(32,1134,499,"双向突破","独立 Magic 与参数");
      Button(32,1177,161,47,"启动突破",PrimaryColor(),PrimaryColor(),TextColor(),true,C(113,92,167));
      Button(201,1177,161,47,"取消挂单",C(229,221,245),C(229,221,245),C(43,35,61),true,C(0,0,0));
      StrongButton(370,1177,161,47,"立即结算",PinkColor(),PinkColor(),C(74,27,39),true,C(0,0,0));
     }

   void DrawStaticLog(void)
     {
      if(m_tab!=AB_PANEL_TAB_BASKET)
         return;
      const int y=931;
      m_canvas.FillRectangle(0,y,m_width,m_height,C(10,11,11));
      m_canvas.LineHorizontal(1,m_width-2,y,BorderColor());
       Text(14,y+10,240,20,"EA 交互提示",20,FW_SEMIBOLD,TextColor(),TA_LEFT);
       Text(490,y+10,55,20,"清空",18,FW_SEMIBOLD,MutedColor(),TA_RIGHT);
     }

   int PageHeight(void) const
     {
      if(m_collapsed)
         return AB_UI_COLLAPSED_HEIGHT;
      int design_height=AB_UI_ORDERS_HEIGHT;
      if(m_tab==AB_PANEL_TAB_BASKET)
         design_height=AB_UI_BASKET_HEIGHT;
      return MathMax(m_config.panel_height,design_height);
     }

   void ResizeForTab(void)
     {
      int target_height=PageHeight();
      if(m_canvas.Width()!=m_width || m_canvas.Height()!=target_height)
         m_canvas.Resize(m_width,target_height);
      m_height=target_height;
      ObjectSetInteger(m_chart_id,m_name,OBJPROP_XDISTANCE,PanelX());
      ObjectSetInteger(m_chart_id,m_name,OBJPROP_YDISTANCE,PanelY());
     }

public:
                     AB_CanvasPanel(void) : m_chart_id(0),m_name("AB_UI_PANEL"),
                        m_tab(AB_PANEL_TAB_ORDERS),m_created(false),m_collapsed(false),
                        m_last_failed_object(""),m_last_failed_error(0),
                        m_width(AB_UI_PANEL_WIDTH),
                        m_height(AB_UI_ORDERS_HEIGHT)
     {
      SetDefaultConfig();
      NormalizeConfig();
     }

   void Configure(const AB_CanvasPanelConfig &config)
     {
      m_config=config;
      NormalizeConfig();
      m_width=m_config.panel_width;
      m_height=PageHeight();
      if(m_created)
         ResizeForTab();
     }

   bool Create(const long chart_id=0)
     {
      m_chart_id=chart_id;
      m_tab=AB_PANEL_TAB_ORDERS;
      m_collapsed=false;
      m_last_failed_object="";
      m_last_failed_error=0;
      NormalizeConfig();
      m_width=m_config.panel_width;
      m_height=PageHeight();
      if(!m_canvas.CreateBitmapLabel(m_name,PanelX(),PanelY(),m_width,m_height,
                                     COLOR_FORMAT_ARGB_NORMALIZE))
        {
         m_last_failed_object=m_name;
         m_last_failed_error=GetLastError();
         return false;
        }
      ObjectSetInteger(m_chart_id,m_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(m_chart_id,m_name,OBJPROP_SELECTED,false);
      ObjectSetInteger(m_chart_id,m_name,OBJPROP_HIDDEN,true);
      m_created=true;
      return true;
     }

   void Destroy(void)
     {
      if(!m_created)
         return;
      m_canvas.Destroy();
      m_created=false;
     }

   void RefreshStatic(void)
     {
      if(!m_created)
         return;
      ResizeForTab();
      m_canvas.Erase(PageColor());
      DrawStaticHeader();
      if(m_collapsed)
        {
         DrawOuterBorder();
         m_canvas.Update(false);
         return;
        }
      DrawTabs();
      if(m_tab==AB_PANEL_TAB_ORDERS)
        {
         DrawStaticOrders();
         DrawBreakout();
        }
      else if(m_tab==AB_PANEL_TAB_BASKET)
         DrawStaticBasket();
      if(m_tab==AB_PANEL_TAB_BASKET)
         DrawStaticLog();
      DrawOuterBorder();
      m_canvas.Update(false);
     }

   AB_PANEL_ACTION HandleClick(const int chart_x,const int chart_y)
     {
      if(!m_created)
         return AB_PANEL_ACTION_NONE;
      int x=chart_x-PanelX();
      int y=chart_y-PanelY();
      if(x<0 || x>=m_width || y<0 || y>=m_height)
         return AB_PANEL_ACTION_NONE;
       if(x>=AB_UI_COLLAPSE_X && x<AB_UI_COLLAPSE_X+AB_UI_COLLAPSE_SIZE &&
          y>=AB_UI_COLLAPSE_Y && y<AB_UI_COLLAPSE_Y+AB_UI_COLLAPSE_SIZE)
        {
         m_collapsed=!m_collapsed;
         ResizeForTab();
         return AB_PANEL_ACTION_NONE;
        }
      if(m_collapsed)
         return AB_PANEL_ACTION_NONE;
      if(y>=106 && y<149)
        {
         if(x>=17 && x<281) m_tab=AB_PANEL_TAB_ORDERS;
         else if(x>=281 && x<546) m_tab=AB_PANEL_TAB_BASKET;
         return AB_PANEL_ACTION_NONE;
        }
      int footer_y=931;
      if(x>=480 && x<546 && y>=footer_y+4 && y<footer_y+35)
        {
         if(m_tab==AB_PANEL_TAB_BASKET)
            return AB_PANEL_ACTION_CLEAR_LOG;
         return AB_PANEL_ACTION_NONE;
        }
      if(m_tab==AB_PANEL_TAB_BASKET)
        {
         if(y>=214 && y<261)
           {
            if(x>=32 && x<193) return AB_PANEL_ACTION_BASKET_MODE_TP;
            if(x>=201 && x<362) return AB_PANEL_ACTION_BASKET_MODE_TRAILING;
            if(x>=370 && x<531) return AB_PANEL_ACTION_BASKET_MODE_ONE_SHOT_SL;
            return AB_PANEL_ACTION_NONE;
           }
         if(x>=149 && x<518 && y>=343 && y<381)
            return AB_PANEL_ACTION_NONE;
         if(x>=149 && x<518 && y>=389 && y<427)
            return AB_PANEL_ACTION_NONE;
         if(y>=517 && y<564)
           {
            if(x>=32 && x<278) return AB_PANEL_ACTION_BASKET_LONG;
            if(x>=285 && x<531) return AB_PANEL_ACTION_BASKET_SHORT;
            return AB_PANEL_ACTION_NONE;
           }
         if(y>=571 && y<618)
           {
            if(x>=32 && x<278) return AB_PANEL_ACTION_BASKET_LONG_NO_LADDER;
            if(x>=285 && x<531) return AB_PANEL_ACTION_BASKET_SHORT_NO_LADDER;
            return AB_PANEL_ACTION_NONE;
           }
         if(y>=625 && y<672 && x>=32 && x<531)
            return AB_PANEL_ACTION_BASKET_CANCEL;
         return AB_PANEL_ACTION_NONE;
        }
      if(m_tab!=AB_PANEL_TAB_ORDERS)
         return AB_PANEL_ACTION_NONE;
      if(y>=321 && y<368)
        {
         if(x>=32 && x<278) return AB_PANEL_ACTION_JOIN_MANAGEMENT;
         if(x>=285 && x<531) return AB_PANEL_ACTION_EXIT_MANAGEMENT;
         return AB_PANEL_ACTION_NONE;
        }
      if(y>=450 && y<497)
        {
         if(x>=32 && x<193) return AB_PANEL_ACTION_AUTO_MODE_M1;
         if(x>=201 && x<362) return AB_PANEL_ACTION_AUTO_MODE_ENTRY;
         if(x>=370 && x<531) return AB_PANEL_ACTION_AUTO_MODE_OFF;
         return AB_PANEL_ACTION_NONE;
       }
      if(y>=507 && y<551 && x>=456 && x<531)
         return AB_PANEL_ACTION_TOGGLE_LADDER;
      if(y>=627 && y<674)
        {
         if(x>=32 && x<278) return AB_PANEL_ACTION_SL_M1;
         if(x>=285 && x<531) return AB_PANEL_ACTION_SL_ENTRY;
         return AB_PANEL_ACTION_NONE;
        }
      if(y>=755 && y<802)
        {
         if(x>=32 && x<151) return AB_PANEL_ACTION_TRAIL_1;
         if(x>=159 && x<278) return AB_PANEL_ACTION_TRAIL_2;
         if(x>=285 && x<404) return AB_PANEL_ACTION_TRAIL_3;
         if(x>=412 && x<531) return AB_PANEL_ACTION_TRAIL_4;
         return AB_PANEL_ACTION_NONE;
        }
      if(y>=809 && y<856 && x>=32 && x<531)
         return AB_PANEL_ACTION_STOP_TRAILING;
      if(y>=938 && y<985)
        {
         if(x>=32 && x<151) return AB_PANEL_ACTION_CLOSE_5;
         if(x>=159 && x<278) return AB_PANEL_ACTION_CLOSE_10;
         if(x>=285 && x<404) return AB_PANEL_ACTION_CLOSE_25;
         if(x>=412 && x<531) return AB_PANEL_ACTION_CLOSE_50;
         return AB_PANEL_ACTION_NONE;
        }
      if(y>=992 && y<1039 && x>=32 && x<531)
         return AB_PANEL_ACTION_CLOSE_ALL;
      if(y>=1046 && y<1093 && x>=32 && x<531)
         return AB_PANEL_ACTION_TRIGGER_NEXT_LEVEL;
      if(y>=1177 && y<1224)
        {
         if(x>=32 && x<193) return AB_PANEL_ACTION_STRADDLE_START;
         if(x>=201 && x<362) return AB_PANEL_ACTION_STRADDLE_CANCEL;
         if(x>=370 && x<531) return AB_PANEL_ACTION_STRADDLE_SETTLE;
         return AB_PANEL_ACTION_NONE;
        }
      return AB_PANEL_ACTION_NONE;
     }

   AB_PANEL_TAB Tab(void) const { return m_tab; }
   bool IsCreated(void) const { return m_created; }
   bool IsCollapsed(void) const { return m_collapsed; }
   void SetBasketParameters(const int trailing,const int reverse_close)
     {
      m_config.basket_trailing=MathMax(0,trailing);
      m_config.basket_reverse_close=MathMax(0,reverse_close);
     }

   string LastFailedObject(void) const { return m_last_failed_object; }
   int LastFailedError(void) const { return m_last_failed_error; }

   int CanvasX(void) const { return PanelX(); }
   int CanvasY(void) const { return PanelY(); }
   int CanvasWidth(void) const { return m_width; }
   int CanvasHeight(void) const { return m_height; }

   bool ContainsPoint(const int chart_x,const int chart_y)
     {
      if(!m_created)
         return false;
      int x=chart_x-PanelX();
      int y=chart_y-PanelY();
      return x>=0 && x<m_width && y>=0 && y<m_height;
     }

   bool IsPanelObject(const string object_name) const
     {
      return object_name==m_name;
     }
  };

#endif
