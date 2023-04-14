public with sharing class Fin_AXSRuleEngineExtController {
    private final Id finAxsRuleEngineId;
    public Fin_AXSRuleEngineExtController (ApexPages.StandardController stdController) {
        finAxsRuleEngineId = ((FIN_AXSRuleEngine__c) stdController.getRecord()).Id;
    }
    public PageReference onSubmit() {
        if (finAxsRuleEngineId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.submit(finAxsRuleEngineId, SBAA__Approval__c.FIN_AXS_Rule_Engine__c);
            //}    
        }
        return new PageReference('/' + finAxsRuleEngineId);
    }
    public PageReference onRecall() {
        if (finAxsRuleEngineId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.recall(finAxsRuleEngineId, SBAA__Approval__c.FIN_AXS_Rule_Engine__c);
            //}   
        }
        return new PageReference('/' + finAxsRuleEngineId);
    }
}