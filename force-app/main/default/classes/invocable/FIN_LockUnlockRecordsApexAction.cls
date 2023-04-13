public class FIN_LockUnlockRecordsApexAction{
  @InvocableMethod(label='Lock and Unlock Records - Apex Action' description='If the record is unlocked , it will be locked and vice-versa')
  public static void doLockUnlock(List<ID> ids) {

    List<ID> idsToLock = new List<ID>();
    List<ID> idsToUnLock = new List<ID>();
    
    for(id a :ids){
        if(Approval.isLocked(a)){
            idsToUnLock.add(a); 
         }
         else {
            idsToLock.add(a); 
        }
    }    
    
    if (idsToLock.size() > 0) {
        Approval.LockResult[] lrList = Approval.lock(idsToLock, false);
     }
     else if (idsToUnLock.size() > 0) {
        Approval.UnLockResult[] lrList = Approval.unlock(idsToUnLock, false);          
     }
  }
}