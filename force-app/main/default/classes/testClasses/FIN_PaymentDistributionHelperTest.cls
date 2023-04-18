@IsTest
private class FIN_PaymentDistributionHelperTest {
    @IsTest
    static void testCreateRetroactiveAdjustment() {
        try {
            List<FIN_RetroactiveAdjustment__c> oldRetroList = [
                SELECT Id
                FROM FIN_RetroactiveAdjustment__c
            ];
            Id paymentRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Payment Distribution').getRecordTypeId();
            Account acc = TestDataFactory.createAccount();
            Contact cont = TestDataFactory.createContactForAccount(acc.Id, 'test@g.com');
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            OrderItem orderItem = TestDataFactory.createTestOrderLine(ord.Id, pro.Id, standardPriceEntry.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, cont.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id,null, cont.Id);

            Test.startTest();
            paymentdist.FIN_AdjustmentAmount__c = 123;
            update paymentdist;

            List<FIN_RetroactiveAdjustment__c> newRetroList = [
                SELECT Id, RecordTypeId
                FROM FIN_RetroactiveAdjustment__c
            ];
            Test.stopTest();

           System.assertEquals(oldRetroList.size()+1, newRetroList.size());
           System.assertEquals(newRetroList[0].RecordTypeId, paymentRecordTypeId);
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testUpdateJournalEntrySignAndAmount() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id,null, contract.Id);

            SBQQ__ContractedPrice__c la = TestDataFactory.createLibraryAssociation(acc.Id);
            paymentdist.FIN_LibraryAssociation__c = la.Id;
            update paymentdist;

            Journalizing_Schedule__c js = TestDataFactory.createJournalizingSchedule(contract.Id);
            js.FIN_Type__c = 'PDs';
            js.FIN_Status__c = 'InProgress';
            update js;

            Integer numOfNewJI = JournalizingDataController.createJI(new List<Id>{
                paymentdist.Id
            }, 'PDs', js.Id);

            List<FIN_Journalizing_Item__c> journalizingItems = [
                SELECT Id, Payment_Distribution__c, FIN_JournalEntryAmount__c
                FROM FIN_Journalizing_Item__c
                WHERE Payment_Distribution__c = :paymentdist.Id
            ];

            Integer newAmount = 120;
            System.assertNotEquals(newAmount, journalizingItems[0].FIN_JournalEntryAmount__c);


            paymentdist.FIN_DistributionAmount__c = newAmount;
            update paymentdist;

            List<FIN_Journalizing_Item__c> journalizingItems2 = [
                SELECT Id, FIN_Payment__c, FIN_JournalEntryAmount__c
                FROM FIN_Journalizing_Item__c
                WHERE FIN_Payment__c = :paymentdist.Id
            ];

            System.assertEquals(newAmount, journalizingItems2[0].FIN_JournalEntryAmount__c);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}