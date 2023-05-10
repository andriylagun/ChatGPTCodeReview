@IsTest
public with sharing class InvoiceDataControllerTest {
    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        Product2 pro = TestDataFactory.createProduct2();
        PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
        OrderItem orderItem = TestDataFactory.createTestOrderLine(ord.Id, pro.Id, standardPriceEntry.Id);
        //orderItem.SBQQ__Contract__c = contract.Id;
        //update orderItem;
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
        paymentdist.Invoices_Status__c = 'ToBeInvoiced';
        update paymentdist;

    }

    @IsTest
    static void testGetFilteredPayments() {
        Contract contract = [
            SELECT Id
            FROM Contract
            WHERE FIN_ParentContract__c != NULL
            LIMIT 1
        ];

        List<Contract> contractsWithPayments = InvoiceDataController.getFilteredSubContractsWithPayments('invoice', contract.Id, '', '', '', '', '');
//        Assert.areEqual(1, contractsWithPayments.size());
    }

    @IsTest
    static void testGetFilteredSTs() {
        Contract contract = [
            SELECT Id
            FROM Contract
            WHERE FIN_ParentContract__c != NULL
            LIMIT 1
        ];

        Map<String,List<OrderItem>> contractsWithSalesTransactions = InvoiceDataController.getFilteredSubContractsWithSalesTransactions(contract.Id, '', '', '');
//        Assert.areEqual(1, contractsWithSalesTransactions.size());
    }

    @IsTest
    static void testCreateIIPDs() {
        Contract contract = [
            SELECT Id
            FROM Contract
            WHERE FIN_ParentContract__c != NULL
            LIMIT 1
        ];
        FIN_PaymentDistribution__c paymentdist = [
            SELECT Id
            FROM FIN_PaymentDistribution__c
            LIMIT 1
        ];

        FIN_InvoiceSchedule__c is = TestDataFactory.createInvoiceSchedule(contract.Id);
        is.FIN_Type__c = FIN_PaymentDistribution__c.SObjectType.getDescribe().getName();
        update is;

        Map<Id, List<Id>> idIdMap = new Map<Id, List<Id>>();
        idIdMap.put(contract.Id, new List<Id>{
            paymentdist.Id
        });
        String json = JSON.serialize(idIdMap);
        Integer resultPDs = InvoiceDataController.createInvoiceItems(json, FIN_PaymentDistribution__c.SObjectType.getDescribe().getName(), new FIN_InvoiceSchedule__c(), is.Id);
//        Assert.areEqual(1, resultPDs);

        List<Contract> contracts = InvoiceDataController.getRelatedRecords(is.Id);
//        Assert.areEqual(1, contracts.size());

        Integer removedPDs = InvoiceDataController.removeRelatedIIs(new List<Id>{
            contract.Id
        }, is.Id);
//        Assert.areEqual(1, removedPDs);
    }

    @IsTest
    static void testCreateIIPayments() {
        Contract contract = [
            SELECT Id
            FROM Contract
            WHERE FIN_ParentContract__c != NULL
            LIMIT 1
        ];
        FIN_Payment__c payment = [
            SELECT Id
            FROM FIN_Payment__c
            LIMIT 1
        ];

        FIN_InvoiceSchedule__c is2 = TestDataFactory.createInvoiceSchedule(contract.Id);
        is2.FIN_Type__c = FIN_Payment__c.SObjectType.getDescribe().getName();
        update is2;

        Map<Id, List<Id>> idIdMap2 = new Map<Id, List<Id>>();
        idIdMap2.put(contract.Id, new List<Id>{
            payment.Id
        });
        String json2 = JSON.serialize(idIdMap2);
        Integer resultPayments = InvoiceDataController.createInvoiceItems(json2, FIN_Payment__c.SObjectType.getDescribe().getName(), new FIN_InvoiceSchedule__c(), is2.Id);
//        Assert.areEqual(1, resultPayments);

        List<Contract> contracts2 = InvoiceDataController.getRelatedRecords(is2.Id);
//        Assert.areEqual(1, contracts2.size());

        Integer removedPayments = InvoiceDataController.removeRelatedIIs(new List<Id>{
            contract.Id
        }, is2.Id);
//        Assert.areEqual(1, removedPayments);
    }

    @IsTest
    static void testCreateIISTs() {
        Contract contract = [
            SELECT Id
            FROM Contract
            WHERE FIN_ParentContract__c != NULL
            LIMIT 1
        ];
        OrderItem st = [
            SELECT Id
            FROM OrderItem
            LIMIT 1
        ];

        FIN_InvoiceSchedule__c is3 = TestDataFactory.createInvoiceSchedule(contract.Id);
        is3.FIN_Type__c = OrderItem.SObjectType.getDescribe().getName();
        update is3;

        Map<Id, List<Id>> idIdMap3 = new Map<Id, List<Id>>();
        idIdMap3.put(contract.Id, new List<Id>{
            st.Id
        });
        String json3 = JSON.serialize(idIdMap3);
        Integer resultSTs = InvoiceDataController.createInvoiceItems(json3, OrderItem.SObjectType.getDescribe().getName(), new FIN_InvoiceSchedule__c(), is3.Id);
//        Assert.areEqual(1, resultSTs);

        List<Contract> contracts3 = InvoiceDataController.getRelatedRecords(is3.Id);
//        Assert.areEqual(1, contracts3.size());

        Integer removedSTs = InvoiceDataController.removeRelatedIIs(new List<Id>{
            contract.Id
        }, is3.Id);
//        Assert.areEqual(1, removedSTs);
    }
}