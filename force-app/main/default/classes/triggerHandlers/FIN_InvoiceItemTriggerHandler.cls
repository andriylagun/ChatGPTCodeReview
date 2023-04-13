public with sharing class FIN_InvoiceItemTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        FIN_InvoiceItemHelper.updateStatusesAfterInsert((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        FIN_InvoiceItemHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }


    protected override void beforeDelete() {
        FIN_InvoiceItemHelper.updateStatusesBeforeDelete((Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }

    protected override void afterDelete() {
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        FIN_InvoiceItemHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }
}