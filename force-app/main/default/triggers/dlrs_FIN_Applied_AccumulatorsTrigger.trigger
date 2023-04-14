/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_FIN_Applied_AccumulatorsTrigger on FIN_Applied_Accumulators__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(FIN_Applied_Accumulators__c.SObjectType);
}