public with sharing class Fin_AXSRuleEngineExtController {
    private Id FIN_AXSRuleEngineId;
    public Fin_AXSRuleEngineExtController (ApexPages.StandardController stdController) {
        FIN_AXSRuleEngineId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (FIN_AXSRuleEngineId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.submit(FIN_AXSRuleEngineId, SBAA__Approval__c.FIN_AXS_Rule_Engine__c);
            //}    
        }
        return new PageReference('/' + FIN_AXSRuleEngineId);
    }
    public PageReference onRecall() {
        if (FIN_AXSRuleEngineId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.recall(FIN_AXSRuleEngineId, SBAA__Approval__c.FIN_AXS_Rule_Engine__c);
            //}   
        }
        return new PageReference('/' + FIN_AXSRuleEngineId);
    }
}