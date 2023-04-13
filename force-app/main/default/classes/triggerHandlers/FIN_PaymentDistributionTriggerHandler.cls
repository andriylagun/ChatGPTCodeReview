public with sharing class FIN_PaymentDistributionTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        FIN_PaymentDistributionHelper.updateOwnerOnClassifiedRecord((List<FIN_PaymentDistribution__c>) this.triggerNew);
        FIN_PaymentDistributionHelper.updateSettlementJournalizingStatuses((List<FIN_PaymentDistribution__c>) this.triggerNew);
    }

    protected override void beforeUpdate() {
        FIN_PaymentDistributionHelper.updateOwnerOnClassifiedRecord((List<FIN_PaymentDistribution__c>) this.triggerNew);
        FIN_PaymentDistributionHelper.updateApprovalStatus((List<FIN_PaymentDistribution__c>) this.triggerNew, (Map<Id, FIN_PaymentDistribution__c>) this.triggerOldMap);
    }

    protected override void afterUpdate() {
        FIN_PaymentDistributionHelper.updateJournalEntrySignAndAmount((List<FIN_PaymentDistribution__c>) this.triggerNew, (Map<Id, FIN_PaymentDistribution__c>) this.triggerOldMap);
        FIN_PaymentDistributionHelper.createRetroactiveAdjustment((List<FIN_PaymentDistribution__c>) this.triggerNew, (Map<Id, FIN_PaymentDistribution__c>) this.triggerOldMap);
    }
}