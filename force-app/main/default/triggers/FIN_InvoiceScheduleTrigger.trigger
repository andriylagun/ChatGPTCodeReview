trigger FIN_InvoiceScheduleTrigger on FIN_InvoiceSchedule__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_InvoiceScheduleTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}