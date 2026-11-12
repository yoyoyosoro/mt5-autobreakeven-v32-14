#ifndef AB_UI_REFRESH_STATE_MQH
#define AB_UI_REFRESH_STATE_MQH

// UI-only scheduling state.  This type deliberately has no position, chart,
// canvas, timer, or trade dependencies.
enum AB_UI_DIRTY_FLAG
  {
   AB_UI_DIRTY_NONE   = 0,
   AB_UI_DIRTY_STATIC = 1,
   AB_UI_DIRTY_HEADER = 2,
   AB_UI_DIRTY_ORDER  = 4,
   AB_UI_DIRTY_BASKET = 8,
   AB_UI_DIRTY_LOG    = 16,
   AB_UI_DIRTY_CHART  = 32,
   AB_UI_DIRTY_LAYOUT = 64
  };

class AB_UiRefreshState
  {
private:
   uint  m_dirty;
   bool  m_flushing;
   ulong m_header_fingerprint;
   ulong m_order_fingerprint;
   ulong m_basket_fingerprint;
   ulong m_log_fingerprint;
   ulong m_chart_fingerprint;

public:
   AB_UiRefreshState(void)
     {
      Reset();
     }

   void Reset(void)
     {
      m_dirty=AB_UI_DIRTY_NONE;
      m_flushing=false;
      m_header_fingerprint=0;
      m_order_fingerprint=0;
      m_basket_fingerprint=0;
      m_log_fingerprint=0;
      m_chart_fingerprint=0;
     }

   void Mark(const uint flags)
     {
      m_dirty|=flags;
     }

   bool Needs(const uint flag) const
     {
      return (m_dirty&flag)!=0;
     }

   void Clear(const uint flags)
     {
      m_dirty&=~flags;
     }

   bool FingerprintChanged(const uint flag,const ulong next_value)
     {
      if(flag==AB_UI_DIRTY_HEADER)
        {
         if(m_header_fingerprint==next_value)
            return false;
         m_header_fingerprint=next_value;
         return true;
        }
      if(flag==AB_UI_DIRTY_ORDER)
        {
         if(m_order_fingerprint==next_value)
            return false;
         m_order_fingerprint=next_value;
         return true;
        }
      if(flag==AB_UI_DIRTY_BASKET)
        {
         if(m_basket_fingerprint==next_value)
            return false;
         m_basket_fingerprint=next_value;
         return true;
        }
      if(flag==AB_UI_DIRTY_LOG)
        {
         if(m_log_fingerprint==next_value)
            return false;
         m_log_fingerprint=next_value;
         return true;
        }
      if(flag==AB_UI_DIRTY_CHART)
        {
         if(m_chart_fingerprint==next_value)
            return false;
         m_chart_fingerprint=next_value;
         return true;
        }
      return false;
     }

   bool BeginFlush(void)
     {
      if(m_flushing)
         return false;
      m_flushing=true;
      return true;
     }

   void EndFlush(void)
     {
      m_flushing=false;
     }
  };

#endif
