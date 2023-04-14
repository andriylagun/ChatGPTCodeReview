public with sharing class FIN_JournalizingItemTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        FIN_JournalizingItemHelper.updateStatusesAfterInsert((List<FIN_Journalizing_Item__c>) this.triggerNew, (Map<Id, FIN_Journalizing_Item__c>)this.triggerOldMap);
    }

    protected override void beforeDelete() {
        FIN_JournalizingItemHelper.updateStatusesBeforeDelete((Map<Id, FIN_Journalizing_Item__c>)this.triggerOldMap);
    }
}