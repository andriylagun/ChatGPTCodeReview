trigger FIN_ResponsePublisherTrigger on FIN_ResponsePublisher__e (after insert) {
    TriggerHandlerFactory.executeHandler(FIN_ResponsePublisherTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}