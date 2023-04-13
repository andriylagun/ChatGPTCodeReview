public with sharing class FIN_contractAssociationExtController {
    private Id contractAssociationId;
    public FIN_contractAssociationExtController (ApexPages.StandardController stdController) {
        contractAssociationId = stdController.getId();
    }
    public PageReference onSubmit() {
        if (contractAssociationId != null) {
           
                SBAA.ApprovalAPI.submit(contractAssociationId, SBAA__Approval__c.contractAssociation__c);
           
        }
        return new PageReference('/' + contractAssociationId);
    }
    public PageReference onRecall() {
        if (contractAssociationId != null) {
            
                SBAA.ApprovalAPI.recall(contractAssociationId, SBAA__Approval__c.contractAssociation__c);
           
        }
        return new PageReference('/' + contractAssociationId);
    }
}