trigger FIN_AXSRuleConditionTrigger on FIN_AXSRuleCondition__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandlerFactory.executeHandler(FIN_AXSRuleConditionTriggerHandler.class, Trigger.operationType, Trigger.new, Trigger.newMap, Trigger.oldMap);
}