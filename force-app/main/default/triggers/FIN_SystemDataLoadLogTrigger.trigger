trigger FIN_SystemDataLoadLogTrigger on FIN_SystemDataLoadLog__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_SystemDataLoadLogTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}