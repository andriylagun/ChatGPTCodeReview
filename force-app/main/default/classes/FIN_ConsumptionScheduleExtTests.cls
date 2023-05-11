@isTest
private class FIN_ConsumptionScheduleExtTests {

    @IsTest
    static void testSubmit() {
        
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;
        
        Test.startTest();
        FIN_ConsumptionScheduleExtController con = new  FIN_ConsumptionScheduleExtController(new ApexPages.StandardController(consSchedule));
        con.onSubmit();
        consSchedule = [SELECT ApprovalStatus__c FROM ConsumptionSchedule WHERE Id = :consSchedule.Id LIMIT 1];
        Test.stopTest();
        
//        System.assertEquals('Approved', consSchedule.ApprovalStatus__c);
    }

    @IsTest
    static void testRecall() {
        ConsumptionSchedule consSchedule = TestDataFactory.createConsumptionSchedule('Revenue_Amount');
        insert consSchedule;
        
        Test.startTest();
        FIN_ConsumptionScheduleExtController con = new FIN_ConsumptionScheduleExtController(new ApexPages.StandardController(consSchedule));
        con.onRecall();
        consSchedule = [SELECT ApprovalStatus__c FROM ConsumptionSchedule WHERE Id = :consSchedule.Id LIMIT 1];
        Test.stopTest();
        
//        System.assertEquals('Recalled', consSchedule.ApprovalStatus__c);
    }
}