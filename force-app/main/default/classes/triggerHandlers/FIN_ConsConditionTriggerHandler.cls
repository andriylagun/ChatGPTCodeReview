/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Consumption Condition trigger handler, used by the Consumption Condition trigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-03-31
* @modified       2022-03-31
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public with sharing class FIN_ConsConditionTriggerHandler extends TriggerHandler{

    public override void afterInsert() {
        // SFCA-449, update Consumption Schedule's approval status on record creation
        FIN_ConsConditionTriggerHandlerHelper.updateConsumptionScheduleApprovalStatus((Map<Id, Accumulator_Condition__c>) Trigger.newMap, null);
    }

    public override void afterUpdate () {
        // SFCA-449, update Consumption Schedule's approval status on record' specified fields update
        FIN_ConsConditionTriggerHandlerHelper.updateConsumptionScheduleApprovalStatus((Map<Id, Accumulator_Condition__c>) Trigger.newMap, (Map<Id, Accumulator_Condition__c>) Trigger.oldMap);
    }

    public override void afterDelete () {
        // SFCA-449, update Consumption Schedule's approval status on record deleting
        FIN_ConsConditionTriggerHandlerHelper.updateConsumptionScheduleApprovalStatus((Map<Id, Accumulator_Condition__c>) Trigger.oldMap, null);
    }
}