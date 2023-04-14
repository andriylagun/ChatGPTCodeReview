@IsTest
private class FIN_SettlementScheduleHelperTest {
    @IsTest
    static void updateStatusesAfterUpdate() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
            FIN_SettlementSchedule__c settlementSchedule = TestDataFactory.createSettlementSchedule(contract.Id);

            FIN_SettlementItem__c settItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentdist.Id);

            Test.startTest();
            settlementSchedule.FIN_Status__c = 'Complete';
            update settlementSchedule;

            List<FIN_PaymentDistribution__c> PDList = [
                SELECT Id, RecordTypeId, FIN_Settlement_Status__c, FIN_Payment__r.FIN_Order__r.Settlement_Status__c
                FROM FIN_PaymentDistribution__c
            ];
            //System.assertEquals(PDList[0].FIN_Settlement_Status__c, 'Invoiced');

            settlementSchedule.FIN_Status__c = 'Void';
            update settlementSchedule;


            List<FIN_PaymentDistribution__c> PDList1 = [
                SELECT Id, RecordTypeId, FIN_Settlement_Status__c, FIN_Payment__r.FIN_Order__r.Settlement_Status__c
                FROM FIN_PaymentDistribution__c
            ];
            System.assertEquals(PDList1[0].FIN_Settlement_Status__c, 'Voided');

            Test.stopTest();
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
    @IsTest
    static void testCreateRemittancePayoutsAfterUpdateTicketPriceComponent() {
        try {

            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
            paymentdist.FIN_DistributionAmountNetofTaxAmount__c = 10;
            update paymentdist;
            FIN_SettlementSchedule__c settlementSchedule = TestDataFactory.createSettlementSchedule(contract.Id);

            SBQQ__ContractedPrice__c library = new SBQQ__ContractedPrice__c(
                SBQQ__Account__c = acc.id,
                FIN_Component_Number__c = 1,
                FIN_Ticket_price_Component__c = 'Venue Delivery Fee',
                //FIN_Fee_and_Component__c = 'Venue Fee',
                SBQQ__Price__c = 100,
                SBQQ__FilterField__c = 'Product',
                SBQQ__Operator__c = 'equals');
            insert library;

            FIN_SettlementItem__c settItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentdist.Id);
            settItem.FIN_LibraryAssociation__c = library.Id;
            update settItem;

            Test.startTest();
            settlementSchedule.FIN_Status__c = 'Remittance';
            update settlementSchedule;

            List<FIN_PaymentDistribution__c> PDList = [
                SELECT Id, FIN_DistributionAmountNetofTaxAmount__c
                FROM FIN_PaymentDistribution__c
            ];
            System.assertEquals(PDList[0].FIN_DistributionAmountNetofTaxAmount__c, 10);

        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
    
    @IsTest
    static void testCreateRemittancePayoutsAfterUpdateFeeAndComponent() {
        try {

            Account acc = TestDataFactory.createAccount();
            Contact cont = TestDataFactory.createContactForAccount(acc.Id, 'test@g.com');
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, cont.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,cont.Id);
            paymentdist.FIN_DistributionAmountNetofTaxAmount__c = 10;
            update paymentdist;

            FIN_SettlementSchedule__c settlementSchedule = new FIN_SettlementSchedule__c();
            insert settlementSchedule;

            SBQQ__ContractedPrice__c library = new SBQQ__ContractedPrice__c(
                SBQQ__Account__c = acc.id,
                FIN_Component_Number__c = 1,
                //FIN_Ticket_price_Component__c = 'Venue Delivery Fee',
                FIN_Fee_and_Component__c = 'Venue Fee',
                SBQQ__Price__c = 100,
                SBQQ__FilterField__c = 'Product',
                SBQQ__Operator__c = 'equals');
            insert library;

            FIN_SettlementItem__c settlementItem = new FIN_SettlementItem__c(
                FIN_PaymentDistribution__c = paymentdist.Id,
                FIN_ParentSettlementSchedule__c = settlementSchedule.id,
                FIN_LibraryAssociation__c = library.id);
            insert settlementItem;
            Test.startTest();
            settlementSchedule.FIN_Status__c = 'Remittance';
            update settlementSchedule;

            List<Remittance_Payout__c> PDList = [
                SELECT Id, FIN_RemittancePayoutAmount__c
                FROM Remittance_Payout__c
            ];
            System.assertEquals(PDList[0].FIN_RemittancePayoutAmount__c, 10);

        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}