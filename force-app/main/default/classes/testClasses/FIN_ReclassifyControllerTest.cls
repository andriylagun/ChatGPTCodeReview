@IsTest
private class FIN_ReclassifyControllerTest {
    @TestSetup
    static void setUp() {
        RecordType clientRecordType = TestDataFactory.getClientRecordType();
        Account acc = TestDataFactory.createClientAccount(clientRecordType.Id);
        Contract parent = TestDataFactory.createParentContract(acc.Id);
        TestDataFactory.createContractAssociation(parent);

        Account venue = TestDataFactory.createVenue();
        insert venue;

        Campaign event = TestDataFactory.createEvent();
        insert event;

        Zone_Types__c zoneType = TestDataFactory.createZoneType();
        insert zoneType;

        Order sale = TestDataFactory.createSale(acc.Id, parent.Id, event.Id, parent.FIN_Context__c, venue.Id, zoneType.Name);
        insert sale;

        FIN_Payment__c payment = TestDataFactory.createPayment(sale.Id, parent.Id);
        Fin_ContractExtController con = new Fin_ContractExtController(new ApexPages.StandardController(parent));
        con.onSubmit();
        FIN_PaymentDistribution__c paymentDis = TestDataFactory.createPaymentDistributionForReclas(payment.Id, sale.Id, parent.Id);
        paymentDis.FIN_TransactionId__c = 'Transaction';
        paymentDis.FIN_PaymentTransactionId__c = 'PaymentTransaction';
        paymentDis.FIN_ContextName__c = parent.FIN_Context__c;
        insert paymentDis;
    }

    @IsTest
    static void testReclassifyController() {
        Test.startTest();
        Contract contract = TestDataFactory.getParentContract()[0];
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);
        FIN_ReclassifyRelatedRecordsController recordsController = new FIN_ReclassifyRelatedRecordsController(sc);
        System.assert(recordsController.onReclassify().getUrl().contains(contract.Id));
        System.assert(recordsController.onReprocess().getUrl().contains(contract.Id));
        Test.stopTest();

    }
}