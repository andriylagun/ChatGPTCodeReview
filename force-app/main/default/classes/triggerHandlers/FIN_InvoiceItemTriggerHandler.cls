public with sharing class FIN_InvoiceItemTriggerHandler extends TriggerHandler {
    
    protected override void afterInsert() {
        FIN_InvoiceItemHelper.checkIfApplicableForConsumption((List<FIN_InvoiceItem__c>) this.triggerNew);
//        FIN_InvoiceItemHelper.updateStatuses((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap, 'InvoiceScheduled');
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        // FIN_InvoiceItemHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_InvoiceItemHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }


    protected override void beforeDelete() {
        FIN_InvoiceItemHelper.updateStatuses(((Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap).values(), ((Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap), 'ToBeInvoiced');
    }

    protected override void afterDelete() {
        FIN_InvoiceItemHelper.createInvoiceLines((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
        FIN_InvoiceItemHelper.updateConsumptionScheduleAmounts((List<FIN_InvoiceItem__c>) this.triggerNew, (Map<Id, FIN_InvoiceItem__c>)this.triggerOldMap);
    }
}