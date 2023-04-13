@IsTest
public with sharing class FIN_SystemDataLoadLogTest {
    @IsTest
    static void testAfterInProgressInsert() {
        try {
            FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c(
                FIN_Process__c = 'Sales',
                FIN_ProcessDate__c = Date.today(),
                FIN_StagingTableLoadCompleteStatus__c = 'Success',
                FIN_BusinessRuleStartTime__c = DateTime.newInstance(2022, 2, 11, 8, 6, 16),
                FIN_BusinessRuleEndTime__c = DateTime.newInstance(2022, 2, 12, 8, 6, 16),
                FIN_Region__c = 'US',
                FIN_BusinessRuleProcessCompleteStatus__c = 'Success',
                FIN_SalesforceRulesStatus__c = 'In-Progress'
            );

            Master_Data_Load__c mdl = new Master_Data_Load__c (
                ProcessDate__c = Date.today(),
                FIN_Region__c = 'US',
                Sales__c = systemDataLoadLog.Id
            );

            Test.startTest();
            insert systemDataLoadLog;
            insert mdl;
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testAfterSuccessInsert() {
        try {
            FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c(
                FIN_Process__c = 'Sales',
                FIN_ProcessDate__c = Date.today(),
                FIN_StagingTableLoadCompleteStatus__c = 'Success',
                FIN_BusinessRuleStartTime__c = DateTime.newInstance(2022, 2, 11, 8, 6, 16),
                FIN_BusinessRuleEndTime__c = DateTime.newInstance(2022, 2, 12, 8, 6, 16),
                FIN_Region__c = 'US',
                FIN_BusinessRuleProcessCompleteStatus__c = 'Success'
            );

            Master_Data_Load__c mdl = new Master_Data_Load__c (
                ProcessDate__c = Date.today(),
                FIN_Region__c = 'US',
                Sales__c = systemDataLoadLog.Id
            );

            Test.startTest();
            insert systemDataLoadLog;
            insert mdl;
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testAfterFailureInsert() {
        try {
            FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c(
                FIN_Process__c = 'Sales',
                FIN_ProcessDate__c = Date.today(),
                FIN_StagingTableLoadCompleteStatus__c = 'Success',
                FIN_BusinessRuleStartTime__c = DateTime.newInstance(2022, 2, 11, 8, 6, 16),
                FIN_BusinessRuleEndTime__c = DateTime.newInstance(2022, 2, 12, 8, 6, 16),
                FIN_Region__c = 'US',
                FIN_BusinessRuleProcessCompleteStatus__c = 'Failure'
            );

            Test.startTest();
            insert systemDataLoadLog;
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}