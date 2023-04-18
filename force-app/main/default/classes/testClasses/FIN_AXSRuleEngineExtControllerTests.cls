@isTest
private class FIN_AXSRuleEngineExtControllerTests {
//FIN_AXSRuleEngineExtControllerTests
    @IsTest
    static void testSubmit() {
        FIN_AXSRuleEngine__c AXSRuleEngine= new FIN_AXSRuleEngine__c(
            FIN_Start_Date__c = Date.today(),
                FIN_Type__c = 'Financial'
        );
        insert AXSRuleEngine;
        
        Test.startTest();
        Fin_AXSRuleEngineExtController con = new Fin_AXSRuleEngineExtController(new ApexPages.StandardController(AXSRuleEngine));
        con.onSubmit();
        AXSRuleEngine= [SELECT ApprovalStatus__c FROM FIN_AXSRuleEngine__c WHERE Id = :AXSRuleEngine.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', AXSRuleEngine.ApprovalStatus__c );
    }

    @IsTest
    static void testRecall() {
        FIN_AXSRuleEngine__c AXSRuleEngine= new FIN_AXSRuleEngine__c(
            FIN_Start_Date__c = Date.today(),
                FIN_Type__c = 'Financial'
        );
        insert AXSRuleEngine;
        
        Test.startTest();
        Fin_AXSRuleEngineExtController con = new Fin_AXSRuleEngineExtController (new ApexPages.StandardController(AXSRuleEngine));
        con.onRecall();
        AXSRuleEngine= [SELECT ApprovalStatus__c  FROM FIN_AXSRuleEngine__c WHERE Id = :AXSRuleEngine.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', AXSRuleEngine.ApprovalStatus__c );
    }
}