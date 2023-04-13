@isTest
private class Fin_OrderExtControllerTests {
    
    testMethod static void testSubmit() {
       
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        Order Order =TestDataFactory.createTestOrder(acc.id);
        
        Test.startTest();
        FIN_OrderExtController con = new FIN_OrderExtController(new ApexPages.StandardController(Order));
        con.onSubmit();
        Order = [SELECT ApprovalStatus__c FROM Order WHERE Id = :Order.Id LIMIT 1];
        Test.stopTest();
        
        //System.assertEquals('Approved', Order.ApprovalStatus__c );
    }
    
    testMethod static void testRecall() {
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        Order Order =TestDataFactory.createTestOrder(acc.id);
        
        Test.startTest();
        FIN_OrderExtController con = new FIN_OrderExtController(new ApexPages.StandardController(Order));
        con.onRecall();
        Order = [SELECT ApprovalStatus__c FROM Order WHERE Id = :Order.Id LIMIT 1];
        Test.stopTest();
        
        //System.assertEquals('Recalled', Order.ApprovalStatus__c);
    }
}