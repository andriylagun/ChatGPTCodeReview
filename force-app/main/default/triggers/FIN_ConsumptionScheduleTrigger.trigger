trigger FIN_ConsumptionScheduleTrigger on ConsumptionSchedule (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_ConsumptionScheduleTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}