@IsTest
public with sharing class SettleDataControllerTest {
    @IsTest
    static void testGetFilteredPDs() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,contract.Id);
        paymentdist.FIN_Settlement_Status__c = 'ToBeSettled';
        update paymentdist;

        List<Contract> listPDs = SettleDataController.getFilteredSubContractsWithPDs('settlement',parentContract.Id,null,null,ord.Id,'',Date.today(),null,'','','');
        System.debug(listPDs);
        //Assert.areEqual(listPDs.size(), 1);
    }

    @IsTest
    static void testGetSales() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);

        List<Order> listOrders = SettleDataController.getSales(parentContract.Id);
        //Assert.areEqual(listOrders.size(), 1);
    }

    @IsTest
    static void testGetZones() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);

        List<Order> listOrders = SettleDataController.getZones(parentContract.Id);
        //Assert.areEqual(listOrders.size(), 1);
    }

    @IsTest
    static void testGetEvents() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,contract.Id);
        paymentdist.FIN_Settlement_Status__c = 'ToBeSettled';
        update paymentdist;

        List<Campaign> listEvents = SettleDataController.getEvents('settlement',parentContract.Id);
//        Assert.areEqual(listEvents.size(), 1);
    }

    @IsTest
    static void testCreateSI() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,contract.Id);
        paymentdist.FIN_Settlement_Status__c = 'ToBeSettled';
        update paymentdist;

        FIN_SettlementSchedule__c ss = TestDataFactory.createSettlementSchedule(contract.Id);

        Integer result = SettleDataController.createSI(new List<Id>{paymentdist.Id},ss.Id);
        Assert.areEqual(result, 1);

        List<Contract> result2 = SettleDataController.getRelatedSubContractsWithPDs(ss.Id);
        Assert.areEqual(result2.size(), 1);

        Integer result3 = SettleDataController.createSI(new List<Id>{paymentdist.Id},ss.Id);
        Assert.areEqual(result3, 1);
    }
}