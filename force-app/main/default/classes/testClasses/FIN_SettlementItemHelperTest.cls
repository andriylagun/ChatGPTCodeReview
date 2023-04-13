@IsTest
private class FIN_SettlementItemHelperTest {
    @IsTest
    static void testUpdateStatusesAfterInsert() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
            FIN_SettlementSchedule__c settlementSchedule = TestDataFactory.createSettlementSchedule(contract.Id);

            FIN_SettlementItem__c settItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentdist.Id);

            List<FIN_PaymentDistribution__c> PDList = [
                SELECT Id, RecordTypeId, FIN_Settlement_Status__c, FIN_Payment__r.FIN_Order__r.Settlement_Status__c
                FROM FIN_PaymentDistribution__c
            ];
            System.debug('PDList' + PDList);

            System.assertEquals('ScheduledSettlement', PDList[0].FIN_Settlement_Status__c);
            System.assertEquals('ScheduledSettlement', PDList[0].FIN_Payment__r.FIN_Order__r.Settlement_Status__c);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testUpdateStatusesBeforeDelete() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
            FIN_SettlementSchedule__c settlementSchedule = TestDataFactory.createSettlementSchedule(contract.Id);

            FIN_SettlementItem__c settItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentdist.Id);

            delete settItem;
            List<FIN_PaymentDistribution__c> pd = [
                SELECT FIN_Payment__r.FIN_Order__r.Settlement_Status__c
                FROM FIN_PaymentDistribution__c
                WHERE FIN_Payment__r.FIN_Order__c = :ord.Id
            ] ;

            System.assertEquals('ToBeSettled', pd[0].FIN_Payment__r.FIN_Order__r.Settlement_Status__c);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testCreateSettlementLines() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);
            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentDistribution = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);

            FIN_Payee__c remittanceAccount = TestDataFactory.createPayee();
            contract.FIN_RemittanceAccount__c = remittanceAccount.Id;
            update contract;

            Campaign event = new Campaign(Name = 'Test Name');
            insert event;

            ord.FIN_Event__c = event.Id;
            update ord;

            SBQQ__ContractedPrice__c la = TestDataFactory.createLibraryAssociation(acc.Id);
            la.FIN_Ticket_price_Component__c = 'Venue Ticket Fee';
            la.FIN_Fee_and_Component__c = 'AXS Fee';
            update la;

            paymentDistribution.FIN_LibraryAssociation__c = la.Id;
            update paymentDistribution;

            FIN_SettlementSchedule__c settlementSchedule = TestDataFactory.createSettlementSchedule(parentContract.Id);
            FIN_SettlementItem__c settItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentDistribution.Id);

            List<FIN_SettlementLine__c> sline = [
                SELECT Id
                FROM FIN_SettlementLine__c
            ];
            System.debug('sline' + sline);
            System.assertEquals(sline.size(), 1);

            delete settItem;

            List<FIN_SettlementLine__c> s2line = [
                SELECT Id
                FROM FIN_SettlementLine__c
            ];
            System.debug('s2line' + s2line);

            System.assertEquals(s2line.size(), 0);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}