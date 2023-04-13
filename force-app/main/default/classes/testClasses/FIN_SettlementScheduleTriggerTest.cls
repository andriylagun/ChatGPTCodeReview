@IsTest
public with sharing class FIN_SettlementScheduleTriggerTest {
    @IsTest
    static void testInsertSettlementSchedule() {
        Account account = TestDataFactory.createAccount();
        Contract ctr = TestDataFactory.createContract(account.Id, null);
        Test.startTest();
        System.assert(TestDataFactory.createSettlementSchedule(ctr.Id).Id != null);
        Test.stopTest();
    }
}