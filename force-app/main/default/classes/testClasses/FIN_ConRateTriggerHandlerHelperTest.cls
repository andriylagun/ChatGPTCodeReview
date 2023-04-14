/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*  Test class for Consumption Rate trigger handler helper logic
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
public with sharing class FIN_ConRateTriggerHandlerHelperTest {

    /**
     * @method      updateApprovalStatusOnCreation
     * @description tests, that method update Consumption Schedule's approval status on record creation.
     * @author      Ivan Liolia - 2022-04-03
     */
    @isTest
    public static void updateApprovalStatusOnCreation() {
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;

        ConsumptionRate consRate = TestDataFactory.createConsumptionRate();
        consRate.ConsumptionScheduleId = consSchedule.Id;

        Assert.areEqual('Approved', consSchedule.FIN_ApprovalStatus__c, 'Status should be Approved');

        Test.startTest();
        insert consRate;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate creation');
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

        ConsumptionRate consRate = TestDataFactory.createConsumptionRate();
        consRate.ConsumptionScheduleId = consSchedule.Id;
        insert consRate;

        consSchedule.FIN_ApprovalStatus__c = 'Approved';
        update consSchedule;

        Test.startTest();
        delete consRate;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate deleting');
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

        ConsumptionRate consRate = TestDataFactory.createConsumptionRate();
        consRate.ConsumptionScheduleId = consSchedule.Id;
        insert consRate;

        consSchedule.FIN_ApprovalStatus__c = 'Approved';
        consSchedule.IsActive = TRUE;
        update consSchedule;

        Test.startTest();
        consRate.UpperBound = 3;
        update consRate;
        Test.stopTest();

        ConsumptionSchedule consScheduleToCheck = [ SELECT FIN_ApprovalStatus__c
                                                    ,      isActive
                                                    FROM   ConsumptionSchedule
                                                    WHERE  Id = :consSchedule.Id];

        Assert.areEqual('New', consScheduleToCheck.FIN_ApprovalStatus__c, 'Status should be updated to New after Rate field changing');
        Assert.areEqual(FALSE, consScheduleToCheck.IsActive, 'isActive should be set to FALSE after Rate field changing');
    }
}