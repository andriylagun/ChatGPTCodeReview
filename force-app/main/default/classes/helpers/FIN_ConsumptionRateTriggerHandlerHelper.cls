/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Consumption Rate trigger handler helper, used by the FIN_ConsumptionRateTriggerHandler
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

public with sharing class FIN_ConsumptionRateTriggerHandlerHelper {

    /**
     * @method      updateConsumptionScheduleApprovalStatus
     * @description SFCA-449 - If ConsumptionRate created, deleted or updated specified fields,
     *              then update Approval Status field to 'New' on parent ConsumptionSchedule record
     * @author      Ivan Liolia - 2023-03-31
     */
    public static void updateConsumptionScheduleApprovalStatus(Map<Id, ConsumptionRate> ratesToIterate, Map<Id, ConsumptionRate> oldRates) {
        Set<String> consumptionScheduleIds = new Set<String>();

        // check if oldRates isn't null, then it comes from update trigger to compare specified values for update
        if (oldRates != null) {
            for (String Id : ratesToIterate.keySet()) {
                if (ratesToIterate.get(Id).LowerBound != oldRates.get(Id).LowerBound ||
                        ratesToIterate.get(Id).UpperBound != oldRates.get(Id).UpperBound ||
                        ratesToIterate.get(Id).PricingMethod != oldRates.get(Id).PricingMethod ||
                        ratesToIterate.get(Id).FIN_Unit_Price__c != oldRates.get(Id).FIN_Unit_Price__c ||
                        ratesToIterate.get(Id).FIN_Rate__c != oldRates.get(Id).FIN_Rate__c) {
                    consumptionScheduleIds.add(ratesToIterate.get(Id).ConsumptionScheduleId);
                }
            }
        }
        // if records come from insert or delete context, then just add ConsumptionScheduleId for subsequent query and update
        else {
            for (String Id : ratesToIterate.keySet()) {
                consumptionScheduleIds.add(ratesToIterate.get(Id).ConsumptionScheduleId);
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