trigger FIN_JournalizingScheduleTrigger on Journalizing_Schedule__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_JournalizingScheduleTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}