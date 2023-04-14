/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for Consumption Condition trigger handler helper logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Ivan Liolia
* @modifiedBy     Ivan Liolia
* @version        1.0
* @created        2022-04-03
* @modified       2022-04-03
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

@isTest
public with sharing class FIN_ConConditionTriggerHandlerHelperTest {

    /**
     * @method      updateApprovalStatusOnCreation
     * @description tests, that method update Consumption Schedule's approval status on record creation.
     * @author      Ivan Liolia - 2022-04-03
     */
    @isTest
    public static void updateApprovalStatusOnCreation() {
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;

        Accumulator_Condition__c consCondition = TestDataFactory.createConsumptionCondition();
        consCondition.FIN_Consumption_Schedule__c = consSchedule.Id;

        Assert.areEqual('Approved', consSchedule.FIN_ApprovalStatus__c, 'Status should be Approved');

        Test.startTest();
        insert consCondition;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Condition creation');
    }

    /**
     * @method      updateApprovalStatusOnDeleting
     * @description tests, that method update Consumption Schedule's approval status on record deleting.
     * @author      Ivan Liolia - 2022-04-03
     */
    @isTest
    public static void updateApprovalStatusOnDeleting() {
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;

        Accumulator_Condition__c consCondition = TestDataFactory.createConsumptionCondition();
        consCondition.FIN_Consumption_Schedule__c = consSchedule.Id;
        insert consCondition;

        consSchedule.FIN_ApprovalStatus__c = 'Approved';
        update consSchedule;

        Test.startTest();
        delete consCondition;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Condition deleting');
    }

    /**
     * @method      updateApprovalStatusOnUpdate
     * @description tests, that method update Consumption Schedule's approval status on record deleting.
     * @author      Ivan Liolia - 2022-04-03
     */
    @isTest
    public static void updateApprovalStatusOnUpdate() {
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;

        Accumulator_Condition__c consCondition = TestDataFactory.createConsumptionCondition();
        consCondition.FIN_Consumption_Schedule__c = consSchedule.Id;
        insert consCondition;

        ConsumptionRate consRate = TestDataFactory.createConsumptionRate();
        consRate.ConsumptionScheduleId = consSchedule.Id;
        insert consRate;

        consSchedule.FIN_ApprovalStatus__c = 'Approved';
        consSchedule.IsActive = TRUE;
        update consSchedule;

        Test.startTest();
        consCondition.Operator__c = '=';
        update consCondition;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate field changing');
        Assert.areEqual(FALSE, consScheduleToCheck.IsActive, 'isActive should be set to FALSE after Rate field changing');
    }

    /**
     * @method      updateApprovalStatusOnConditionReassign
     * @description tests, that method update Consumption Schedule's approval status for old
     *              and new ConsSchedule when we reassign ConsCondition
     * @author      Ivan Liolia - 2022-04-03
     */
    @isTest
    public static void updateApprovalStatusOnConditionReassign() {
        ConsumptionSchedule consScheduleFirst = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consScheduleFirst;

        Accumulator_Condition__c consCondition = TestDataFactory.createConsumptionCondition();
        consCondition.FIN_Consumption_Schedule__c = consScheduleFirst.Id;
        insert consCondition;

        consScheduleFirst.FIN_ApprovalStatus__c = 'Approved';
        update consScheduleFirst;

        ConsumptionSchedule consScheduleSecond = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consScheduleSecond;

        Test.startTest();
        consCondition.FIN_Consumption_Schedule__c = consScheduleSecond.Id;
        update consCondition;
        Test.stopTest();

        ConsumptionSchedule consScheduleFirstToCheck = [SELECT FIN_ApprovalStatus__c
                                                        ,      isActive
                                                        FROM   ConsumptionSchedule
                                                        WHERE  Id = :consScheduleFirst.Id];

        ConsumptionSchedule consScheduleSecondToCheck = [   SELECT FIN_ApprovalStatus__c
                                                            ,      isActive
                                                            FROM   ConsumptionSchedule
                                                            WHERE  Id = :consScheduleSecond.Id];

        Assert.areEqual('New', consScheduleFirstToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate field changing for old cons Schedule');
        Assert.areEqual('New', consScheduleSecondToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate field changing for a new cons Schedule');
    }
}