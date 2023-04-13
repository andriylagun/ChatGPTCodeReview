@IsTest
public with sharing class JournalizingDataControllerTest {
    @IsTest
    static void testCreateJI() {
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
        Assert.areEqual(1, numOfNewJI);

        Journalizing_Schedule__c js2 = TestDataFactory.createJournalizingSchedule(contract.Id);
        js2.FIN_Type__c = 'Payments';
        js2.FIN_Status__c = 'InProgress';
        update js2;

        Integer numOfNewJI2 = JournalizingDataController.createJI(new List<Id>{
            payment2.Id
        }, 'Payments', js2.Id);
        Assert.areEqual(1, numOfNewJI2);
    }

    @IsTest
    static void testGetRelatedRecords() {
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

        List<Contract> listRelatedRecords = JournalizingDataController.getRelatedRecords(js.Id);
        Assert.areEqual(1, listRelatedRecords.size());

        Journalizing_Schedule__c js2 = TestDataFactory.createJournalizingSchedule(contract.Id);

        js2.FIN_Type__c = 'Payments';
        js2.FIN_Status__c = 'InProgress';
        update js2;

        Integer numOfNewJI2 = JournalizingDataController.createJI(new List<Id>{
            payment2.Id
        }, 'Payments', js2.Id);

        List<Contract> listRelatedRecords2 = JournalizingDataController.getRelatedRecords(js2.Id);
        Assert.areEqual(1, listRelatedRecords2.size());
    }

    @IsTest
    static void testDeleteJI() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
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

        Integer numOfDeletedJI = JournalizingDataController.removeRelatedJIs(new List<Id>{
            contract.Id
        }, js.Id);
        Assert.areEqual(1, numOfDeletedJI);

        List<Contract> listRelatedRecords = JournalizingDataController.getRelatedRecords(js.Id);
        Assert.areEqual(0, listRelatedRecords.size());
    }
}