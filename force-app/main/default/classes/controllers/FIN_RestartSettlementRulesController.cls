public with sharing class FIN_RestartSettlementRulesController {
    public FIN_RestartSettlementRulesController(ApexPages.StandardSetController standardController) { }

    public PageReference onRulesRestart() {
        FIN_AXSRuleEngineService.processSettlementRules(UserSelector.getCurrentUserWithRegion().FIN_Current_Region__c);
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/o/FIN_AXSRuleEngine__c/home');
    }
}