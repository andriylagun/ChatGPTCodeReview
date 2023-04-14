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
        Product2 pro = TestDataFactory.createProduct2ByName('TICKET1');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pro.Id);

        OrderItem saleTransaction = TestDataFactory.createTestOrderLine(sale.Id, pro.Id, pbe.Id);
        saleTransaction.SBQQ__Contract__c = parent.Id;
        saleTransaction.FIN_Missing_Library_Association__c = true;
        update saleTransaction;

        SBQQ__ContractedPrice__c la = TestDataFactory.createLibraryAssociation(acc.Id);
        la.FIN_Context__c = parent.FIN_Context__c;
        la.SBQQ__Product__c = pro.Id;
        la.Association_Type__c = 'Ticket';
        la.FIN_Component_Number__c = 1;
        la.SBQQ__EffectiveDate__c = Date.today().addMonths(-10);
        la.SBQQ__FilterField__c = '';
        la.SBQQ__ExpirationDate__c = Date.today().addMonths(10);
        update la;
        la.FIN_ApprovalStatus__c = 'Approved';
        update la;
        System.debug('la: ' + la.FIN_ApprovalStatus__c);
        System.debug(la.FIN_ApprovalStatus__c == 'Approved' && la.SBQQ__EffectiveDate__c < Date.today() && la.SBQQ__ExpirationDate__c > Date.today());
        System.debug([SELECT Id, FIN_Context__c, FIN_Fee_Category__c, Association_Type__c, FIN_Component_Number__c, FIN_ContextName__c, FIN_ProductName__c, FIN_Active__c FROM SBQQ__ContractedPrice__c limit 1]);
        RecordType record = [
                SELECT Id
                FROM RecordType
                WHERE Name = 'US Payment'
        ];
        FIN_Payment__c payment = new FIN_Payment__c(
                FIN_Order__c = sale.Id,
                FIN_PaymentDate__c = System.today(),
                RecordTypeId = record.Id,
                CurrencyIsoCode = 'USD',
                FIN_Invoices_Status__c = 'ToBeInvoiced',
                FIN_ApprovalStatus__c = 'Approved',
                Contract__c = parent.Id,
                FIN_Context__c = parent.FIN_Context__c,
                FIN_TransactionId__c = 'Transaction'
        );
        insert payment;
        Fin_ContractExtController con = new Fin_ContractExtController(new ApexPages.StandardController(parent));
        con.onSubmit();
        FIN_PaymentDistribution__c paymentDis = TestDataFactory.createPaymentDistributionForReclas(payment.Id, sale.Id, parent.Id);
        paymentDis.FIN_TransactionId__c = 'Transaction';
        paymentDis.FIN_PaymentTransactionId__c = 'PaymentTransaction';
        paymentDis.FIN_ContextName__c = parent.FIN_Context__c;
        paymentDis.FIN_EnrichedLibraryAssociation__c = la.Id;
        insert paymentDis;
    }

    @IsTest
    static void testReclassifyController() {
        Test.startTest();
        Contract contract = TestDataFactory.getParentContract()[0];
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);
        FIN_ReclassifyRelatedRecordsController recordsController = new FIN_ReclassifyRelatedRecordsController(sc);
        System.debug([SELECT Id, FIN_ContextName__c, FIN_Context__c, FIN_Fee_Category__c, FIN_ProductName__c, Association_Type__c, FIN_Component_Number__c FROM SBQQ__ContractedPrice__c WHERE (FIN_ContextName__c != NULL AND FIN_ProductName__c != NULL AND FIN_Context__c = :contract.FIN_Context__c AND FIN_Active__c = TRUE)]);
        System.assert(recordsController.onReclassify().getUrl().contains(contract.Id));
        System.assert(recordsController.onReprocess().getUrl().contains(contract.Id));
        Test.stopTest();

    }
}