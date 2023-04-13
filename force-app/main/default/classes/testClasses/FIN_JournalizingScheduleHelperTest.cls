@IsTest
private class FIN_JournalizingScheduleHelperTest {
    @IsTest
    static void testUpdateStatusesAfterUpdate() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_Payment__c payment2 = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
        paymentdist.FIN_Settlement_Status__c = 'ToBeSettled';
        update paymentdist;

        Journalizing_Schedule__c js = TestDataFactory.createJournalizingSchedule(contract.Id);
        js.FIN_Type__c = 'PDs';
        js.FIN_Status__c = 'InProgress';
        update js;

        Integer numOfNewJI = JournalizingDataController.createJI(new List<Id>{
            paymentdist.Id
        }, 'PDs', js.Id);

        FIN_PaymentDistribution__c pd = [
            SELECT Id, FIN_Journalizing_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id =: paymentdist.Id
            LIMIT 1
        ];

        Assert.areEqual('InProgress', pd.FIN_Journalizing_Status__c);

        js.FIN_Status__c = 'Posted';
        update js;

        FIN_PaymentDistribution__c pd2 = [
            SELECT Id, FIN_Journalizing_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id =: paymentdist.Id
            LIMIT 1
        ];

        Assert.areEqual('Posted', pd2.FIN_Journalizing_Status__c);

        Journalizing_Schedule__c js2 = TestDataFactory.createJournalizingSchedule(contract.Id);

        js2.FIN_Type__c = 'Payments';
        js2.FIN_Status__c = 'InProgress';
        update js2;

        Integer numOfNewJI2 = JournalizingDataController.createJI(new List<Id>{
            payment2.Id
        }, 'Payments', js2.Id);

        FIN_Payment__c paym = [
            SELECT Id, FIN_Journalizing_Status__c
            FROM FIN_Payment__c
            WHERE Id =: payment2.Id
            LIMIT 1
        ];

        Assert.areEqual('InProgress', paym.FIN_Journalizing_Status__c);

        js2.FIN_Status__c = 'Posted';
        update js2;

        FIN_Payment__c paym2 = [
            SELECT Id, FIN_Journalizing_Status__c
            FROM FIN_Payment__c
            WHERE Id =: payment2.Id
            LIMIT 1
        ];

        Assert.areEqual('Posted', paym2.FIN_Journalizing_Status__c);
    }
}