trigger FIN_MasterDataLoadTrigger on Master_Data_Load__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_MasterDataLoadTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}