public with sharing class Fin_ContractExtController {
    private Id ContractId;
    public Fin_ContractExtController (ApexPages.StandardController stdController) {
        ContractId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (ContractId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.submit(ContractId, SBAA__Approval__c.Contract__c);
            //}
        }
        return new PageReference('/' + ContractId);
    }
    public PageReference onRecall() {
        if (ContractId != null) {
            //if(!Test.isRunningTest()){
                SBAA.ApprovalAPI.recall(ContractId, SBAA__Approval__c.Contract__c);
            //}    
        }
        return new PageReference('/' + ContractId);
    }
}