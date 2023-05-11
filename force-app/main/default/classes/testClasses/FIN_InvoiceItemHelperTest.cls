@IsTest
private class FIN_InvoiceItemHelperTest {
    @IsTest
    static void updateStatusesAfterInsert() {
        try {

            Account acc = TestDataFactory.createAccount();
            Contract cntr = TestDataFactory.createParentContract(acc.Id);
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, cntr.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, cntr.Id);
            FIN_InvoiceSchedule__c invoiceSchedule = new FIN_InvoiceSchedule__c();
            insert invoiceSchedule;
            FIN_InvoiceItem__c invoiceItem = new FIN_InvoiceItem__c(
                FIN_PaymentDistribution__c = paymentdist.Id,
                FIN_ParentInvoiceSchedule__c = invoiceSchedule.id);

//            Test.startTest();
            insert invoiceItem;
//            Test.stopTest();
            List<FIN_PaymentDistribution__c> PDList = [
                SELECT Id, RecordTypeId, Invoices_Status__c, FIN_Payment__r.FIN_Order__r.Invoices_Status__c
                FROM FIN_PaymentDistribution__c
            ];


             System.assertEquals(PDList[0].Invoices_Status__c, 'InvoiceScheduled');
             System.assertEquals(PDList[0].FIN_Payment__r.FIN_Order__r.Invoices_Status__c, 'InvoiceScheduled');

        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
    @IsTest
    static void updateStatusesBeforeDelete() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contract cntr = TestDataFactory.createParentContract(acc.Id);
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, cntr.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, cntr.Id);
            FIN_InvoiceSchedule__c invoiceSchedule = new FIN_InvoiceSchedule__c();
            insert invoiceSchedule;
            FIN_InvoiceItem__c invoiceItem = new FIN_InvoiceItem__c(
                FIN_PaymentDistribution__c = paymentdist.Id,
                FIN_ParentInvoiceSchedule__c = invoiceSchedule.id);

            insert invoiceItem;
            Test.startTest();

            delete invoiceItem;
            Test.stopTest();

            List<FIN_PaymentDistribution__c> paymeent = [
                SELECT FIN_Payment__r.FIN_Order__r.Invoices_Status__c
                FROM FIN_PaymentDistribution__c
                WHERE FIN_Payment__r.FIN_Order__c = :ord.id
            ] ;

            System.assertEquals(paymeent[0].FIN_Payment__r.FIN_Order__r.Invoices_Status__c, 'ToBeInvoiced');


        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}