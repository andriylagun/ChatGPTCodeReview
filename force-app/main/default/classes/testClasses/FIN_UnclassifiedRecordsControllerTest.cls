@IsTest
public with sharing class FIN_UnclassifiedRecordsControllerTest {
    @IsTest
    static void testOnSalesClassify() {
        try {
            Test.startTest();
            PageReference pageRef = Page.ClassifySalesRecords;

            Account acc = TestDataFactory.createAccount();
            Order ord = TestDataFactory.createTestOrder(acc.Id);

            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id', ord.Id);

            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(new List<Order>{
                ord
            });
            FIN_UnclassifiedRecordsController controller = new FIN_UnclassifiedRecordsController(sc);

            System.assertNotEquals(null, controller.onSalesClassify());
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testOnPaymentsClassify() {
        try {
            Test.startTest();
            PageReference pageRef = Page.ClassifySalesRecords;

            Account acc = TestDataFactory.createAccount();
            Order ord = TestDataFactory.createTestOrder(acc.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id,null);

            Test.setCurrentPage(pageRef);

            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(new List<FIN_Payment__c>{
                payment
            });
            FIN_UnclassifiedRecordsController controller = new FIN_UnclassifiedRecordsController(sc);

            System.assertNotEquals(null, controller.onPaymentsClassify());
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testPaymentsDistributionClassify() {
        try {
            Test.startTest();
            PageReference pageRef = Page.ClassifySalesRecords;

            Account acc = TestDataFactory.createAccount();
            Contract contract = TestDataFactory.createParentContract(acc.Id);
            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id,contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);

            Test.setCurrentPage(pageRef);

            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(new List<FIN_PaymentDistribution__c>{
                paymentdist
            });
            FIN_UnclassifiedRecordsController controller = new FIN_UnclassifiedRecordsController(sc);

            System.assertNotEquals(null, controller.onPaymentsDistributionClassify());
            Test.stopTest();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}