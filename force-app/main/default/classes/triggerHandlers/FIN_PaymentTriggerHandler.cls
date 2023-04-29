public with sharing class FIN_PaymentTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        FIN_PaymentHelper.mapPaymentToRelatedSaleContract((List<FIN_Payment__c>) this.triggerNew);
        FIN_PaymentHelper.updateOwnerOnClassifiedRecord((List<FIN_Payment__c>) this.triggerNew);
        FIN_PaymentHelper.updateSettlementJournalizingStatuses((List<FIN_Payment__c>) this.triggerNew);
    }

    protected override void beforeUpdate() {
        FIN_PaymentHelper.mapPaymentToRelatedSaleContract((List<FIN_Payment__c>) this.triggerNew);
        FIN_PaymentHelper.updateOwnerOnClassifiedRecord((List<FIN_Payment__c>) this.triggerNew);
        FIN_PaymentHelper.updateApprovalStatus((List<FIN_Payment__c>) this.triggerNew, (Map<Id, FIN_Payment__c>) this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_PaymentHelper.updateJournalEntrySignAndAmount((List<FIN_Payment__c>) this.triggerNew, (Map<Id, FIN_Payment__c>) this.triggerOldMap);
//        FIN_PaymentHelper.createRetroactiveAdjustment((List<FIN_Payment__c>) this.triggerNew, (Map<Id, FIN_Payment__c>) this.triggerOldMap);
    }
}