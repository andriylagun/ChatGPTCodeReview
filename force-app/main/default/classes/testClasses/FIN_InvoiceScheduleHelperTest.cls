@IsTest
private class FIN_InvoiceScheduleHelperTest {
    @IsTest
    static void updateStatusesAfterUpdate() {
        try {
            Account acc = TestDataFactory.createAccount();
            Contact cont = TestDataFactory.createContactForAccount(acc.Id, 'test@g.com');
            Product2 pro = TestDataFactory.createProduct2();
            PricebookEntry standardPriceEntry = TestDataFactory.createPricebookEntry(pro.Id);
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, cont.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,cont.Id);
            FIN_InvoiceSchedule__c invoiceSchedule = new FIN_InvoiceSchedule__c();
            insert invoiceSchedule;
            FIN_InvoiceItem__c invoiceItem = new FIN_InvoiceItem__c(
                FIN_PaymentDistribution__c = paymentdist.Id,
                FIN_ParentInvoiceSchedule__c = invoiceSchedule.id);
            insert invoiceItem;


            Test.startTest();
            invoiceSchedule.FIN_Status__c = 'Complete';
            update invoiceSchedule;

            List<FIN_PaymentDistribution__c> PDList = [
                SELECT Id, RecordTypeId, Invoices_Status__c, FIN_Payment__r.FIN_Order__r.Invoices_Status__c
                FROM FIN_PaymentDistribution__c
            ];
//            System.assertEquals(PDList[0].Invoices_Status__c, 'Invoiced');


            invoiceSchedule.FIN_Status__c = 'Void';
            update invoiceSchedule;


            List<FIN_PaymentDistribution__c> PDList1 = [
                SELECT Id, RecordTypeId, Invoices_Status__c, FIN_Payment__r.FIN_Order__r.Invoices_Status__c
                FROM FIN_PaymentDistribution__c
            ];
//            System.assertEquals('Voided', PDList1[0].Invoices_Status__c);

            Test.stopTest();


        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }
}