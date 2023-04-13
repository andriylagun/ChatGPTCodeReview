trigger FIN_PaymentDistributionTrigger on FIN_PaymentDistribution__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_PaymentDistributionTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}