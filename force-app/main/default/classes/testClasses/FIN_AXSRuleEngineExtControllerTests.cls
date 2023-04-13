@isTest
private class FIN_AXSRuleEngineExtControllerTests {
//FIN_AXSRuleEngineExtControllerTests
    testMethod static void testSubmit() {
        FIN_AXSRuleEngine__c AXSRuleEngine= new FIN_AXSRuleEngine__c(
            FIN_Start_Date__c = Date.today(),
                FIN_Type__c = 'Financial'
        );
        insert AXSRuleEngine;
        
        Test.startTest();
        FIN_AXSRuleEngineExtController con = new FIN_AXSRuleEngineExtController(new ApexPages.StandardController(AXSRuleEngine));
        con.onSubmit();
        AXSRuleEngine= [SELECT ApprovalStatus__c FROM FIN_AXSRuleEngine__c WHERE Id = :AXSRuleEngine.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', AXSRuleEngine.ApprovalStatus__c );
    }
    
    testMethod static void testRecall() {
        FIN_AXSRuleEngine__c AXSRuleEngine= new FIN_AXSRuleEngine__c(
            FIN_Start_Date__c = Date.today(),
                FIN_Type__c = 'Financial'
        );
        insert AXSRuleEngine;
        
        Test.startTest();
        FIN_AXSRuleEngineExtController con = new FIN_AXSRuleEngineExtController (new ApexPages.StandardController(AXSRuleEngine));
        con.onRecall();
        AXSRuleEngine= [SELECT ApprovalStatus__c  FROM FIN_AXSRuleEngine__c WHERE Id = :AXSRuleEngine.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', AXSRuleEngine.ApprovalStatus__c );
    }
}