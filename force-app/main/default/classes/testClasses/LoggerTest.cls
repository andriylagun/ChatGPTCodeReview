@IsTest
public with sharing class LoggerTest {
    @TestSetup
    static void setUp() {
        insert new FIN_SystemDataLoadLog__c(FIN_Process__c = 'Sales', FIN_ProcessDate__c = System.now(), FIN_ReturnedFromSaleTransactions__c = true);
    }

    @IsTest
    static void testLoggerLog() {
        Test.startTest();
        FIN_SystemDataLoadLog__c systemDataLoadLog = [SELECT Id FROM FIN_SystemDataLoadLog__c WHERE FIN_ReturnedFromSaleTransactions__c = TRUE];
        Logger.log(new AuraHandledException('Test'), systemDataLoadLog.Id, 'US');
        System.assertEquals(1, [SELECT Id, FIN_Process__c FROM FIN_System_Log__c WHERE FIN_Process__c = :systemDataLoadLog.Id].size());
        Test.stopTest();
    }
}