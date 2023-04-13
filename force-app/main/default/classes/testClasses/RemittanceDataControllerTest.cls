@IsTest
private class RemittanceDataControllerTest {
    @TestSetup
    static void setUp() {
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
        settlementSchedule.FIN_Status__c = 'Remittance';
        update settlementSchedule;

        SBQQ__ContractedPrice__c library = TestDataFactory.createLibraryAssociation(acc.Id);
        library.FIN_Fee_and_Component__c = 'Venue Fee';
        update library;

        FIN_SettlementItem__c settlementItem = TestDataFactory.createSettlementItem(contract.Id, settlementSchedule.Id, paymentdist.Id);
        Remittance_Payout__c rp = TestDataFactory.createRemittancePayout(settlementSchedule.Id, contract.Id);
    }

    @IsTest
    public static void testFilteredRPs() {
        List<FIN_SettlementSchedule__c> settlementSchedules = [
            SELECT Id
            FROM FIN_SettlementSchedule__c
        ];

        List<Remittance_Payout__c> remittancePayouts = RemittanceDataController.getFilteredRPs(null, null, '', '', settlementSchedules[0].Id);

        Assert.areEqual(1, remittancePayouts.size());
    }

    @IsTest
    public static void testGetPayees() {
        List<FIN_Payee__c> payees = RemittanceDataController.getPayees(null);

        Assert.areEqual(1, payees.size());
    }

    @IsTest
    public static void testGetContracts() {
        List<Contract> contracts = RemittanceDataController.getContracts(null);

        Assert.areEqual(1, contracts.size());
    }

    @IsTest
    public static void testSSNums() {
        List<FIN_SettlementSchedule__c> settlementSchedules = RemittanceDataController.getSSNums(null);

        Assert.areEqual(1, settlementSchedules.size());
    }

    @IsTest
    public static void testCreateRI() {
        FIN_RemittanceSchedule__c remittanceSchedule = TestDataFactory.createRemittanceSchedule();
        List<Remittance_Payout__c> remittancePayouts = [
            SELECT Id
            FROM Remittance_Payout__c
        ];

        Integer riQty = RemittanceDataController.createRI(new List<Id>{
            remittancePayouts[0].Id
        }, remittanceSchedule.Id);

        Assert.areEqual(1, riQty);
    }
}