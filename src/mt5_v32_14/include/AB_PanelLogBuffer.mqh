#ifndef AB_PANEL_LOG_BUFFER_MQH
#define AB_PANEL_LOG_BUFFER_MQH

class AB_PanelLogBuffer
  {
private:
   datetime m_time[20];
   string   m_text[20];
   int      m_capacity;
   int      m_count;
   int      m_next;

   void Mix(ulong &value,const ulong item) const
     {
      value=(value^item)*1099511628211;
     }

   void MixText(ulong &value,const string text) const
     {
      Mix(value,(ulong)StringLen(text));
      for(int index=0;index<StringLen(text);index++)
         Mix(value,(ulong)StringGetCharacter(text,index));
     }

public:
                     AB_PanelLogBuffer(void) : m_capacity(7),m_count(0),m_next(0)
     {
      for(int index=0;index<20;index++)
        {
         m_time[index]=0;
         m_text[index]="";
        }
     }

   void Add(const datetime timestamp,const string text)
     {
      if(text=="")
         return;
      m_time[m_next]=timestamp;
      m_text[m_next]=text;
      m_next=(m_next+1)%m_capacity;
      if(m_count<m_capacity)
         m_count++;
     }

   void Clear(void)
     {
      for(int index=0;index<20;index++)
        {
         m_time[index]=0;
         m_text[index]="";
        }
      m_count=0;
      m_next=0;
     }

   void SetCapacity(const int capacity)
     {
      int next_capacity=MathMax(1,MathMin(20,capacity));
      if(next_capacity==m_capacity)
         return;
      datetime saved_time[20];
      string saved_text[20];
      int keep=MathMin(m_count,next_capacity);
      int first_logical=m_count-keep;
      for(int index=0;index<keep;index++)
        {
         int source=m_next-m_count+first_logical+index;
         while(source<0)
            source+=m_capacity;
         source%=m_capacity;
         saved_time[index]=m_time[source];
         saved_text[index]=m_text[source];
        }
      Clear();
      m_capacity=next_capacity;
      for(int index=0;index<keep;index++)
         Add(saved_time[index],saved_text[index]);
     }

   void BuildView(AB_PanelLogView &view) const
     {
      view.count=MathMin(m_count,5);
      for(int index=0;index<5;index++)
        {
         view.times[index]=0;
         view.lines[index]="";
        }
      for(int index=0;index<view.count;index++)
        {
         int source=m_next-1-index;
         while(source<0)
            source+=m_capacity;
         source%=m_capacity;
         view.times[index]=m_time[source];
         view.lines[index]=m_text[source];
        }
     }

   ulong Fingerprint(void) const
     {
      AB_PanelLogView view;
      BuildView(view);
      ulong value=1469598103934665603;
      Mix(value,(ulong)view.count);
      for(int index=0;index<view.count;index++)
        {
         Mix(value,(ulong)view.times[index]);
         MixText(value,view.lines[index]);
        }
      return value;
     }

   int Capacity(void) const { return m_capacity; }
   int Count(void) const { return m_count; }
  };

#endif
