trigger FIN_SettlementScheduleTrigger on FIN_SettlementSchedule__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_SettlementScheduleHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}