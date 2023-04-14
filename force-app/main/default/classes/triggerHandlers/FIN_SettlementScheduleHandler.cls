public with sharing class FIN_SettlementScheduleHandler extends TriggerHandler {
    protected override void afterUpdate() {
        FIN_SettlementScheduleHelper.updateStatusesAfterUpdate((List<FIN_SettlementSchedule__c>) this.triggerNew, (Map<Id, FIN_SettlementSchedule__c>)this.triggerOldMap);
        FIN_SettlementScheduleHelper.createRemittancePayoutsAfterUpdate((List<FIN_SettlementSchedule__c>) this.triggerNew, (Map<Id, FIN_SettlementSchedule__c>)this.triggerOldMap);
    }
}