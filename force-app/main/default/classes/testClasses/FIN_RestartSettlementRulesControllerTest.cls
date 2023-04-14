@IsTest
private class FIN_RestartSettlementRulesControllerTest {
    @IsTest
    static void testBehavior() {
        Test.startTest();
        List<FIN_AXSRuleEngine__c> mockupList = new List<FIN_AXSRuleEngine__c>{};
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(mockupList);
        FIN_RestartSettlementRulesController recordsController = new FIN_RestartSettlementRulesController(sc);
        recordsController.onRulesRestart();
        Test.stopTest();
    }
}