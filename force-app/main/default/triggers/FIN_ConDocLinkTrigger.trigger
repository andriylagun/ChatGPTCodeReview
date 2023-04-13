trigger FIN_ConDocLinkTrigger on ContentDocumentLink (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_ConDocLinkTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}