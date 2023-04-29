trigger FIN_RecordsForwarderTrigger on FIN_RecordsForwarder__e (after insert) {
    TriggerHandlerFactory.executeHandler(FIN_RecordsForwarderTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}