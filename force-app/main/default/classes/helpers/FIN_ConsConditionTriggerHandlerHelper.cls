/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Consumption Condition trigger handler helper, used by the FIN_ConsConditionTriggerHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-03-31
* @modified       2022-01-31
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public with sharing class FIN_ConsConditionTriggerHandlerHelper {

    /**
     * @method      updateConsumptionScheduleApprovalStatus
     * @description SFCA-449 - If Consumption Condition created, deleted or updated specified fields,
     *              then update Approval Status field to 'New' on parent ConsumptionSchedule record
     * @author      Ivan Liolia - 2023-03-31
     */
    public static void updateConsumptionScheduleApprovalStatus(Map<Id, Accumulator_Condition__c> conditionsToIterate, Map<Id, Accumulator_Condition__c> oldConditions) {
        Set<String> consumptionScheduleIds = new Set<String>();

        // check if oldConditions isn't null, then it comes from update trigger to compare specified values for update
        if (oldConditions != null) {
            for (String Id : conditionsToIterate.keySet()) {
                if (conditionsToIterate.get(Id).Object__c != oldConditions.get(Id).Object__c ||
                        conditionsToIterate.get(Id).FIN_Object_Attribute__c != oldConditions.get(Id).FIN_Object_Attribute__c ||
                        conditionsToIterate.get(Id).Operator__c != oldConditions.get(Id).Operator__c ||
                        conditionsToIterate.get(Id).FIN_Value__c != oldConditions.get(Id).FIN_Value__c ||
                        conditionsToIterate.get(Id).FIN_Library_Association__c != oldConditions.get(Id).FIN_Library_Association__c ||
                        conditionsToIterate.get(Id).FIN_Consumption_Schedule__c != oldConditions.get(Id).FIN_Consumption_Schedule__c) {
                    consumptionScheduleIds.add(conditionsToIterate.get(Id).FIN_Consumption_Schedule__c);
                    consumptionScheduleIds.add(oldConditions.get(Id).FIN_Consumption_Schedule__c);
                }
            }
        }
        // if records come from insert or delete context, then just add ConsumptionScheduleId for subsequent query and update
        else {
            for (String Id : conditionsToIterate.keySet()) {
                consumptionScheduleIds.add(conditionsToIterate.get(Id).FIN_Consumption_Schedule__c);
            }
        }

        // query parent ConsumptionSchedule records with not 'New' status
        List<ConsumptionSchedule> consSchedules =  [SELECT Id
                                                    ,      FIN_ApprovalStatus__c
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id IN :consumptionScheduleIds
                                                    AND    FIN_ApprovalStatus__c != 'New'];

        // update status for queried parent ConsumptionSchedule records to 'New'
        if (!consSchedules.isEmpty()) {
            for (ConsumptionSchedule consSchedule : consSchedules) {
                consSchedule.FIN_ApprovalStatus__c = 'New';
                consSchedule.IsActive = FALSE;
            }

            update consSchedules;
        }
    }
}