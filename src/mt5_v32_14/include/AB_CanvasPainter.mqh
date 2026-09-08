#ifndef AB_CANVAS_PAINTER_MQH
#define AB_CANVAS_PAINTER_MQH

#include <Canvas\Canvas.mqh>

// Shared pixel primitives for the static panel and the transparent dynamic
// layers.  The target canvas is always explicit so a draw call cannot
// accidentally write to another layer.
class AB_CanvasPainter
  {
private:
   static uint C(const int r,const int g,const int b)
     {
      return XRGB(r,g,b);
     }

   int FontPx(const int px) const
     {
      if(px<=11)
         return px+6;
      if(px<=12)
         return px+5;
      return px+4;
     }

   string LatinFontFace(const int role) const
     {
      if(role==FW_NORMAL)
         return "::resources\\fonts\\Inter-Regular.ttf";
      if(role==FW_MEDIUM)
         return "::resources\\fonts\\Inter-Medium.ttf";
      return "::resources\\fonts\\Inter-SemiBold.ttf";
     }

   string DigitFontFace(const int role) const
     {
      return LatinFontFace(role);
     }

   string InterFontFamily(const int role) const
     {
      if(role==FW_NORMAL)
         return "Inter";
      if(role==FW_MEDIUM)
         return "Inter Medium";
      return "Inter SemiBold";
     }

   bool SetLatinFont(CCanvas &canvas,const int px,const int role) const
     {
      canvas.FontSet(LatinFontFace(role),px,FW_NORMAL);
      if(canvas.FontSet(InterFontFamily(role),px,FW_NORMAL))
         return true;
      return canvas.FontSet("Arial",px,role);
     }

   bool SetDigitFont(CCanvas &canvas,const int px,const int role) const
     {
      return SetLatinFont(canvas,px,role);
     }

   bool SetCjkFont(CCanvas &canvas,const int px,const int role) const
     {
      // MT5 reliably distinguishes the installed Noto family at 400 and 600.
      // HTML's intermediate 500 role is intentionally mapped to regular.
      const int cjk_role=(role==FW_NORMAL)
                         ? FW_NORMAL
                         : (role==FW_MEDIUM ? FW_MEDIUM : FW_SEMIBOLD);
      if(canvas.FontSet("Noto Sans SC",px,cjk_role))
         return true;
      return canvas.FontSet("Microsoft YaHei UI",px,cjk_role);
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

   int RunWidth(CCanvas &canvas,const string value,const int px,
                const int role,const int kind) const
     {
      if(kind==2)
        {
         if(!SetDigitFont(canvas,px,role))
            return 0;
        }
      else if(kind==1)
        {
         if(!SetLatinFont(canvas,px,role))
            return 0;
        }
      else
        {
         if(!SetCjkFont(canvas,px,role))
            return 0;
        }
      return canvas.TextWidth(value);
     }

   int MixedTextWidth(CCanvas &canvas,const string value,const int px,
                      const int role) const
     {
      if(StringLen(value)<=0)
         return 0;
      int total=0;
      int length=StringLen(value);
      int start=0;
      int kind=TextRunKind((ushort)StringGetCharacter(value,0));
      for(int i=1;i<length;i++)
        {
         int now_kind=TextRunKind((ushort)StringGetCharacter(value,i));
         if(now_kind==kind)
            continue;
         total+=RunWidth(canvas,StringSubstr(value,start,i-start),px,role,kind);
         start=i;
         kind=now_kind;
        }
      total+=RunWidth(canvas,StringSubstr(value,start),px,role,kind);
      return total;
     }

   int MixedTextHeight(CCanvas &canvas,const int px,const int role) const
     {
      int height=0;
      if(SetLatinFont(canvas,px,role))
         height=(int)MathMax(height,canvas.TextHeight("Ag"));
      if(SetDigitFont(canvas,px,role))
         height=(int)MathMax(height,canvas.TextHeight("0123456789"));
      if(SetCjkFont(canvas,px,role))
         height=(int)MathMax(height,canvas.TextHeight("自动"));
      return height;
     }

   int DrawTextRun(CCanvas &canvas,const int x,const int y,const int h,
                   const string value,const int px,const int role,
                   const int kind,const uint clr) const
     {
      int width=RunWidth(canvas,value,px,role,kind);
      int run_height=canvas.TextHeight(value);
      int run_y=y+(h-run_height)/2;
      canvas.TextOut(x,run_y,value,clr,TA_LEFT);
      return width;
     }

   void FillRoundedAA(CCanvas &canvas,const int x,const int y,const int w,
                      const int h,const int radius,const uint fill) const
     {
      if(w<=0 || h<=0)
         return;
      int limit=(int)MathMin(w,h)/2;
      int r=MathMax(1,MathMin(radius,limit));
      canvas.FillRectangle(x+r,y,x+w-r-1,y+h-1,fill);
      canvas.FillRectangle(x,y+r,x+w-1,y+h-r-1,fill);
      canvas.FillCircle(x+r,y+r,r,fill);
      canvas.FillCircle(x+w-r-1,y+r,r,fill);
      canvas.FillCircle(x+r,y+h-r-1,r,fill);
      canvas.FillCircle(x+w-r-1,y+h-r-1,r,fill);
     }

   void RoundedQuarterArcAA(CCanvas &canvas,const int center_x,
                            const int center_y,const int radius,
                            const double start_angle,const uint clr) const
     {
      int segments=(int)MathMax(12,radius*4);
      double step=(3.14159265358979323846*0.5)/(double)segments;
      for(int i=0;i<=segments;i++)
        {
         double angle=start_angle+step*i;
         canvas.PixelSetAA((double)center_x+(double)radius*MathCos(angle),
                           (double)center_y+(double)radius*MathSin(angle),clr);
        }
     }

   uint Blend(const uint base,const uint overlay,const int alpha) const
     {
      int a=MathMax(0,MathMin(255,alpha));
      int inverse=255-a;
      int r=((int)GETRGBR(base)*inverse+(int)GETRGBR(overlay)*a+127)/255;
      int g=((int)GETRGBG(base)*inverse+(int)GETRGBG(overlay)*a+127)/255;
      int b=((int)GETRGBB(base)*inverse+(int)GETRGBB(overlay)*a+127)/255;
      return C(r,g,b);
     }

   uint TextureLine(const uint fill,const uint requested) const
     {
      if(requested==C(255,255,255))
         return Blend(fill,C(255,255,255),15);
      if(requested==C(0,0,0))
         return Blend(fill,C(0,0,0),10);
      return requested;
     }

   void DiagonalTexture(CCanvas &canvas,const int x,const int y,const int w,
                        const int h,const uint line_color,const int radius) const
     {
      if(w<=0 || h<=0)
         return;
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
         canvas.Line(x1,y1,x2,y2,line_color);
        }
     }

public:
   int MeasureText(CCanvas &canvas,const string text,const int size,
                   const int weight) const
     {
      if(text=="")
         return 0;
      return MixedTextWidth(canvas,text,FontPx(size),weight);
     }

   bool Text(CCanvas &canvas,const int x,const int y,const int w,const int h,
             const string text,const int size,const int weight,
             const uint clr,const int align) const
     {
      if(text=="" || w<=0 || h<=0)
         return false;
      int font_px=FontPx(size);
      int text_width=MixedTextWidth(canvas,text,font_px,weight);
      int text_x=x;
      if(align==TA_CENTER)
         text_x=x+(w-text_width)/2;
      else if(align==TA_RIGHT)
         text_x=x+w-text_width;
      int length=StringLen(text);
      int start=0;
      int run_x=text_x;
      int kind=TextRunKind((ushort)StringGetCharacter(text,0));
      for(int i=1;i<length;i++)
        {
         int now_kind=TextRunKind((ushort)StringGetCharacter(text,i));
         if(now_kind==kind)
            continue;
         string run=StringSubstr(text,start,i-start);
         int width=DrawTextRun(canvas,run_x,y,h,run,font_px,weight,kind,clr);
         run_x+=width;
         start=i;
         kind=now_kind;
        }
      string tail=StringSubstr(text,start);
      DrawTextRun(canvas,run_x,y,h,tail,font_px,weight,kind,clr);
      return true;
     }

   void RoundedBox(CCanvas &canvas,const int x,const int y,const int w,
                   const int h,const int radius,const uint fill,
                   const uint border) const
     {
      FillRoundedAA(canvas,x,y,w,h,radius,border);
      FillRoundedAA(canvas,x+1,y+1,w-2,h-2,MathMax(0,radius-1),fill);
      int limit=(int)MathMin(w,h)/2;
      int r=MathMax(1,MathMin(radius,limit));
      canvas.LineAA(x+r,y,x+w-r-1,y,border);
      canvas.LineAA(x+w-1,y+r,x+w-1,y+h-r-1,border);
      canvas.LineAA(x+w-r-1,y+h-1,x+r,y+h-1,border);
      canvas.LineAA(x,y+h-r-1,x,y+r,border);
      RoundedQuarterArcAA(canvas,x+r,y+r,r,3.14159265358979323846,border);
      RoundedQuarterArcAA(canvas,x+w-r-1,y+r,r,
                          3.14159265358979323846*1.5,border);
      RoundedQuarterArcAA(canvas,x+w-r-1,y+h-r-1,r,0.0,border);
      RoundedQuarterArcAA(canvas,x+r,y+h-r-1,r,
                          3.14159265358979323846*0.5,border);
     }

   void ButtonRole(CCanvas &canvas,const int x,const int y,const int w,
                   const int h,const string text,const uint fill,
                   const uint border,const uint text_color,
                   const bool textured,const uint texture_color,
                    const int weight,const int text_size=18) const
     {
      RoundedBox(canvas,x,y,w,h,5,fill,border);
      if(textured)
         DiagonalTexture(canvas,x,y,w,h,
                         TextureLine(fill,texture_color==0 ? C(255,255,255) : texture_color),4);
      Text(canvas,x,y,w,h,text,text_size,weight,text_color,TA_CENTER);
     }

   void Button(CCanvas &canvas,const int x,const int y,const int w,const int h,
               const string text,const uint fill,const uint border,
               const uint text_color,const bool textured,
               const uint texture_color) const
     {
      ButtonRole(canvas,x,y,w,h,text,fill,border,text_color,textured,
                  texture_color,FW_SEMIBOLD);
     }

   void DisabledButton(CCanvas &canvas,const int x,const int y,const int w,
                       const int h,const string text,const uint fill,
                       const uint border,const uint text_color) const
     {
      uint disabled_fill=Blend(C(18,21,31),fill,97);
      uint disabled_border=Blend(C(18,21,31),border,97);
      uint disabled_text=Blend(C(18,21,31),text_color,97);
      ButtonRole(canvas,x,y,w,h,text,disabled_fill,disabled_border,
                 disabled_text,true,C(0,0,0),FW_SEMIBOLD);
     }
  };

#endif
