@IsTest
public with sharing class InvoiceDataControllerTest {
    @IsTest
    static void testGetFilteredRecords() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id,contract.Id);
        Product2 pro = TestDataFactory.createProduct2();
        PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
        OrderItem orderItem = TestDataFactory.createTestOrderLine(ord.Id, pro.Id, standardPriceEntry.Id);

        List<Contract> listPayments = InvoiceDataController.getFilteredSubContractsWithPayments('invoice',parentContract.Id, ord.Id, '', '','','');
//        Assert.areEqual(listPayments.size(), 1);

        List<Contract> listSalesTr = InvoiceDataController.getFilteredSubContractsWithSalesTransactions(parentContract.Id, ord.Id, '', '');
//        Assert.areEqual(listSalesTr.size(), 1);
    }

    @IsTest
    static void testFunctionalityInvoiceItems() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        Product2 pro = TestDataFactory.createProduct2();
        PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
        OrderItem orderItem = TestDataFactory.createTestOrderLine(ord.Id, pro.Id, standardPriceEntry.Id);

        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id,contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,contract.Id);
        paymentdist.Invoices_Status__c = 'ToBeInvoiced';
        update paymentdist;

        FIN_InvoiceSchedule__c ii = TestDataFactory.createInvoiceSchedule(contract.Id);
        Map<Id, List<Id>> idIdMap = new Map<Id, List<Id>>();
        idIdMap.put(contract.Id, new List<Id>{paymentdist.Id});
        System.debug('idIdMap'+idIdMap);
        String json = JSON.serialize(idIdMap);
        System.debug('idIdMap'+idIdMap.toString());

        Integer result = InvoiceDataController.createInvoiceItems(json, 'PDs', new FIN_InvoiceSchedule__c(),ii.Id);
//        Assert.areEqual(result, 1);
        System.debug('after create');

        FIN_InvoiceSchedule__c ii2 = TestDataFactory.createInvoiceSchedule(contract.Id);
        Map<Id, List<Id>> idIdMap2 = new Map<Id, List<Id>>();
        idIdMap2.put(contract.Id, new List<Id>{payment.Id});
         json = idIdMap2.toString();
        Integer result2 = InvoiceDataController.createInvoiceItems(json, 'Payments', ii2,ii2.Id);
//        Assert.areEqual(result2, 1);

        FIN_InvoiceSchedule__c ii3 = TestDataFactory.createInvoiceSchedule(contract.Id);
        Map<Id, List<Id>> idIdMap3 = new Map<Id, List<Id>>();
        idIdMap3.put(contract.Id, new List<Id>{orderItem.Id});
        json = idIdMap3.toString();
        Integer result3 = InvoiceDataController.createInvoiceItems(json,'SalesTransactions', ii3,ii3.Id);
//        Assert.areEqual(result3, 1);


        List<Object> listPDs = InvoiceDataController.getRelatedRecords(ii.Id);
//        Assert.areEqual(listPDs.size(), 1);

        List<Object> listPayments = InvoiceDataController.getRelatedRecords(ii2.Id);
//        Assert.areEqual(listPayments.size(), 1);

        List<Object> listSalesTr = InvoiceDataController.getRelatedRecords(ii3.Id);
//        Assert.areEqual(listSalesTr.size(), 1);


        // Integer deletedPDsSize = InvoiceDataController.removeRelatedIIs(new List<Id>{paymentdist.Id}, ii.Id);
        // Assert.areEqual(deletedPDsSize, 1);

        // Integer deletedPaymentsSize = InvoiceDataController.removeRelatedIIs(new List<Id>{payment.Id}, ii2.Id);
        // Assert.areEqual(deletedPaymentsSize, 1);

        // Integer deletedSalesTrSize = InvoiceDataController.removeRelatedIIs(new List<Id>{orderItem.Id}, ii3.Id);
        // Assert.areEqual(deletedSalesTrSize, 1);
    }
}