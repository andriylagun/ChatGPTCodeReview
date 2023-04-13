public with sharing class FIN_InvoiceScheduleTriggerHandler  extends TriggerHandler {
    protected override void afterInsert() {
//        FIN_InvoiceScheduleHelper.runAccumulationRules((List<FIN_InvoiceSchedule__c>) this.triggerNew, (Map<Id, FIN_InvoiceSchedule__c>) this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_InvoiceScheduleHelper.updateStatusesAfterUpdate((List<FIN_InvoiceSchedule__c>) this.triggerNew, (Map<Id, FIN_InvoiceSchedule__c>) this.triggerOldMap);
        FIN_InvoiceScheduleHelper.createSettlementItemInvoiceAdj((List<FIN_InvoiceSchedule__c>) this.triggerNew, (Map<Id, FIN_InvoiceSchedule__c>) this.triggerOldMap);
        FIN_InvoiceScheduleHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceSchedule__c>) this.triggerNew, (Map<Id, FIN_InvoiceSchedule__c>) this.triggerOldMap);
    }
}