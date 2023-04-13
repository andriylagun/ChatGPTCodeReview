public with sharing class FIN_SettlementItemTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        FIN_SettlementItemHelper.updateStatusesAfterInsert((List<FIN_SettlementItem__c>) this.triggerNew, (Map<Id, FIN_SettlementItem__c>)this.triggerOldMap);
        FIN_SettlementItemHelper.createSettlementLines((List<FIN_SettlementItem__c>) this.triggerNew, (Map<Id, FIN_SettlementItem__c>)this.triggerOldMap);
    }
//    protected override void afterUpdate() {
//        FIN_SettlementItemHelper.createSettlementLines((List<FIN_SettlementItem__c>) this.triggerNew, (Map<Id, FIN_SettlementItem__c>)this.triggerOldMap);
//    }
    protected override void beforeDelete() {
        FIN_SettlementItemHelper.updateStatusesBeforeDelete((Map<Id, FIN_SettlementItem__c>)this.triggerOldMap);
    }

    protected override void afterDelete() {
        FIN_SettlementItemHelper.createSettlementLines((List<FIN_SettlementItem__c>) this.triggerNew, (Map<Id, FIN_SettlementItem__c>)this.triggerOldMap);
    }
}