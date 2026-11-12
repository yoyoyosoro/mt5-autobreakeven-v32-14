#ifndef AB_PERSISTENCE_MQH
#define AB_PERSISTENCE_MQH

#include "AB_Types.mqh"

#define AB_STATE_FORMAT_VERSION 2

string AB_SanitizeFilePart(string value)
  {
   StringReplace(value,"\\","_");
   StringReplace(value,"/","_");
   StringReplace(value,":","_");
   StringReplace(value," ","_");
   return value;
  }

string AB_LedgerNamespace(void)
  {
   return "ABV32_04_mt5_"+
      IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN))+"_"+
      AB_SanitizeFilePart(AccountInfoString(ACCOUNT_SERVER))+"_"+
      AB_SanitizeFilePart(_Symbol);
  }

string AB_StateFileA(void) { return AB_LedgerNamespace()+"_state_A.bin"; }
string AB_StateFileB(void) { return AB_LedgerNamespace()+"_state_B.bin"; }
string AB_StateCommitFile(void) { return AB_LedgerNamespace()+"_state_commit.bin"; }

struct AB_PersistedState
  {
   ulong sequence;
   ulong next_entity_id;
   bool recovery_required;
   bool unknown_request;
   // Runtime manifest is persisted with the transaction envelope. Detailed
   // objects remain owned by their engines; these fields make recovery
   // deterministic before any price-driven work is allowed.
   int normal_lineage_count;
   int breakout_lineage_count;
   int normal_ladder_count;
   int breakout_ladder_count;
   int long_basket_phase;
   int short_basket_phase;
   int straddle_phase;
   int operation_count;
   ulong unknown_request_id;
  };

void AB_WriteUlong(const int handle,const ulong value)
  {
   uchar bytes[8];
   for(int i=0;i<8;i++)
      bytes[i]=(uchar)((value>>(8*i))&0xFF);
   FileWriteArray(handle,bytes,0,8);
  }

ulong AB_ReadUlong(const int handle)
  {
   uchar bytes[8];
   ArrayInitialize(bytes,0);
   if(FileReadArray(handle,bytes,0,8)!=8)
      return 0;
   ulong value=0;
   for(int i=0;i<8;i++)
      value|=((ulong)bytes[i])<<(8*i);
   return value;
  }

bool AB_LocalFileExists(const string file_name)
  {
   int handle=FileOpen(file_name,FILE_BIN|FILE_READ);
   if(handle==INVALID_HANDLE)
      return false;
   FileClose(handle);
   return true;
  }

ulong AB_StateChecksum(const AB_PersistedState &state)
  {
   ulong value=1469598103934665603;
   value=(value^state.sequence)*1099511628211;
   value=(value^state.next_entity_id)*1099511628211;
   value=(value^(state.recovery_required ? 1 : 0))*1099511628211;
   value=(value^(state.unknown_request ? 1 : 0))*1099511628211;
   value=(value^(ulong)state.normal_lineage_count)*1099511628211;
   value=(value^(ulong)state.breakout_lineage_count)*1099511628211;
   value=(value^(ulong)state.normal_ladder_count)*1099511628211;
   value=(value^(ulong)state.breakout_ladder_count)*1099511628211;
   value=(value^(ulong)state.long_basket_phase)*1099511628211;
   value=(value^(ulong)state.short_basket_phase)*1099511628211;
   value=(value^(ulong)state.straddle_phase)*1099511628211;
   value=(value^(ulong)state.operation_count)*1099511628211;
   value=(value^state.unknown_request_id)*1099511628211;
   return value;
  }

bool AB_WriteStateFile(const string file_name,const AB_PersistedState &state)
  {
   int handle=FileOpen(file_name,FILE_BIN|FILE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;
   FileWriteInteger(handle,AB_STATE_FORMAT_VERSION,INT_VALUE);
   AB_WriteUlong(handle,state.sequence);
   AB_WriteUlong(handle,state.next_entity_id);
   FileWriteInteger(handle,state.recovery_required ? 1 : 0,INT_VALUE);
   FileWriteInteger(handle,state.unknown_request ? 1 : 0,INT_VALUE);
   FileWriteInteger(handle,state.normal_lineage_count,INT_VALUE);
   FileWriteInteger(handle,state.breakout_lineage_count,INT_VALUE);
   FileWriteInteger(handle,state.normal_ladder_count,INT_VALUE);
   FileWriteInteger(handle,state.breakout_ladder_count,INT_VALUE);
   FileWriteInteger(handle,state.long_basket_phase,INT_VALUE);
   FileWriteInteger(handle,state.short_basket_phase,INT_VALUE);
   FileWriteInteger(handle,state.straddle_phase,INT_VALUE);
   FileWriteInteger(handle,state.operation_count,INT_VALUE);
   AB_WriteUlong(handle,state.unknown_request_id);
   AB_WriteUlong(handle,AB_StateChecksum(state));
   FileFlush(handle);
   FileClose(handle);
   return true;
  }

bool AB_ReadStateFile(const string file_name,AB_PersistedState &state)
  {
   int handle=FileOpen(file_name,FILE_BIN|FILE_READ);
   if(handle==INVALID_HANDLE)
      return false;
   int version=FileReadInteger(handle,INT_VALUE);
   state.sequence=AB_ReadUlong(handle);
   state.next_entity_id=AB_ReadUlong(handle);
   state.recovery_required=(FileReadInteger(handle,INT_VALUE)!=0);
   state.unknown_request=(FileReadInteger(handle,INT_VALUE)!=0);
   state.normal_lineage_count=FileReadInteger(handle,INT_VALUE);
   state.breakout_lineage_count=FileReadInteger(handle,INT_VALUE);
   state.normal_ladder_count=FileReadInteger(handle,INT_VALUE);
   state.breakout_ladder_count=FileReadInteger(handle,INT_VALUE);
   state.long_basket_phase=FileReadInteger(handle,INT_VALUE);
   state.short_basket_phase=FileReadInteger(handle,INT_VALUE);
   state.straddle_phase=FileReadInteger(handle,INT_VALUE);
   state.operation_count=FileReadInteger(handle,INT_VALUE);
   state.unknown_request_id=AB_ReadUlong(handle);
   ulong checksum=AB_ReadUlong(handle);
   FileClose(handle);
   return version==AB_STATE_FORMAT_VERSION && checksum==AB_StateChecksum(state);
  }

bool AB_WriteCommitMarker(const int slot,const ulong sequence)
  {
   int handle=FileOpen(AB_StateCommitFile(),FILE_BIN|FILE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;
   FileWriteInteger(handle,slot,INT_VALUE);
   AB_WriteUlong(handle,sequence);
   FileFlush(handle);
   FileClose(handle);
   return true;
  }

bool AB_ReadCommitMarker(int &slot,ulong &sequence)
  {
   int handle=FileOpen(AB_StateCommitFile(),FILE_BIN|FILE_READ);
   if(handle==INVALID_HANDLE)
      return false;
   slot=FileReadInteger(handle,INT_VALUE);
   sequence=AB_ReadUlong(handle);
   FileClose(handle);
   return slot==0 || slot==1;
  }

class AB_Persistence
  {
private:
   AB_PersistedState m_state;
   bool m_loaded;
   bool m_recovery_gate;

public:
   AB_Persistence(void)
     {
      m_state.sequence=0;
      m_state.next_entity_id=1;
      m_state.recovery_required=false;
      m_state.unknown_request=false;
      m_state.normal_lineage_count=0;
      m_state.breakout_lineage_count=0;
      m_state.normal_ladder_count=0;
      m_state.breakout_ladder_count=0;
      m_state.long_basket_phase=0;
      m_state.short_basket_phase=0;
      m_state.straddle_phase=0;
      m_state.operation_count=0;
      m_state.unknown_request_id=0;
      m_loaded=false;
      m_recovery_gate=true;
     }

   bool LoadLatest(void)
     {
      AB_PersistedState state_a,state_b;
      string file_a=AB_StateFileA();
      string file_b=AB_StateFileB();
      bool exists_a=AB_LocalFileExists(file_a);
      bool exists_b=AB_LocalFileExists(file_b);
      bool valid_a=AB_ReadStateFile(file_a,state_a);
      bool valid_b=AB_ReadStateFile(file_b,state_b);
      if(!exists_a && !exists_b)
        {
         m_state.sequence=0;
         m_state.next_entity_id=1;
         m_state.recovery_required=false;
         m_state.unknown_request=false;
         m_state.normal_lineage_count=0;
         m_state.breakout_lineage_count=0;
         m_state.normal_ladder_count=0;
         m_state.breakout_ladder_count=0;
         m_state.long_basket_phase=0;
         m_state.short_basket_phase=0;
         m_state.straddle_phase=0;
         m_state.operation_count=0;
         m_state.unknown_request_id=0;
         m_loaded=true;
         m_recovery_gate=false;
         return true;
        }
      if(!valid_a && !valid_b)
        {
         m_loaded=true;
         m_recovery_gate=true;
         return true;
        }
      int committed_slot=-1;
      ulong committed_sequence=0;
      bool has_commit=AB_ReadCommitMarker(committed_slot,committed_sequence);
      if(has_commit && committed_slot==0 && valid_a && state_a.sequence==committed_sequence)
         m_state=state_a;
      else if(has_commit && committed_slot==1 && valid_b && state_b.sequence==committed_sequence)
         m_state=state_b;
      else if(valid_a && (!valid_b || state_a.sequence>=state_b.sequence))
         m_state=state_a;
      else
         m_state=state_b;
      m_loaded=true;
      m_recovery_gate=m_state.recovery_required || m_state.unknown_request;
      return true;
     }

   bool Save(void)
     {
      if(!m_loaded)
         return false;
      m_state.sequence++;
      int slot=(int)(m_state.sequence%2);
      string file_name=(slot==0 ? AB_StateFileA() : AB_StateFileB());
      if(!AB_WriteStateFile(file_name,m_state))
         return false;
      AB_PersistedState verified;
      if(!AB_ReadStateFile(file_name,verified) || verified.sequence!=m_state.sequence)
         return false;
      bool committed=AB_WriteCommitMarker(slot,m_state.sequence);
      return committed;
     }

   void SetRecoveryRequired(const bool value)
     {
      m_state.recovery_required=value;
      m_recovery_gate=value || m_state.unknown_request;
     }

   void SetUnknownRequest(const bool value)
     {
      m_state.unknown_request=value;
      m_recovery_gate=value || m_state.recovery_required;
     }

   void SetUnknownRequestId(const ulong request_id)
     {
      m_state.unknown_request_id=request_id;
      m_state.unknown_request=request_id!=0;
      m_recovery_gate=m_state.unknown_request || m_state.recovery_required;
     }

   bool HasUnknownRequest(void) const { return m_state.unknown_request; }

   // Called only after the caller has checked position/order/deal history.
   bool ResolveUnknownRequestAfterHistoryCheck(const bool history_is_final)
     {
      if(!history_is_final)
         return false;
      m_state.unknown_request=false;
      m_state.unknown_request_id=0;
      m_recovery_gate=m_state.recovery_required;
      return Save();
     }

   void SetRuntimeManifest(const int normal_lineage_count,
                           const int breakout_lineage_count,
                           const int normal_ladder_count,
                           const int breakout_ladder_count,
                           const int long_basket_phase,
                           const int short_basket_phase,
                           const int straddle_phase,
                           const int operation_count)
     {
      m_state.normal_lineage_count=normal_lineage_count;
      m_state.breakout_lineage_count=breakout_lineage_count;
      m_state.normal_ladder_count=normal_ladder_count;
      m_state.breakout_ladder_count=breakout_ladder_count;
      m_state.long_basket_phase=long_basket_phase;
      m_state.short_basket_phase=short_basket_phase;
      m_state.straddle_phase=straddle_phase;
      m_state.operation_count=operation_count;
     }

   bool RecoveryRequiresHistoryCheck(void) const
     {
      return m_state.recovery_required || m_state.unknown_request;
     }

   bool RuntimeManifestMatches(const int normal_lineage_count,
                               const int breakout_lineage_count,
                               const int normal_ladder_count,
                               const int breakout_ladder_count) const
     {
      return m_state.normal_lineage_count==normal_lineage_count &&
             m_state.breakout_lineage_count==breakout_lineage_count &&
             m_state.normal_ladder_count==normal_ladder_count &&
             m_state.breakout_ladder_count==breakout_ladder_count;
     }

   bool CanIssueNewActions(void) const
     {
      return m_loaded && !m_recovery_gate;
     }

   ulong Sequence(void) const { return m_state.sequence; }
   bool HasCommittedState(void) const { return m_state.sequence>0; }
   int PersistedNormalLineageCount(void) const { return m_state.normal_lineage_count; }
   int PersistedBreakoutLineageCount(void) const { return m_state.breakout_lineage_count; }
   int PersistedNormalLadderCount(void) const { return m_state.normal_ladder_count; }
   int PersistedBreakoutLadderCount(void) const { return m_state.breakout_ladder_count; }

   ulong AllocateEntityId(void)
     {
      return m_state.next_entity_id++;
     }
  };

#endif
