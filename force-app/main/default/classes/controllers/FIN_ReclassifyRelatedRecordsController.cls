public with sharing class FIN_ReclassifyRelatedRecordsController {
    private final Contract ctrct;
    private final List<Contract> contracts;
    private final List<String> contractsIds;

    public FIN_ReclassifyRelatedRecordsController(ApexPages.StandardController stdController) {
        this.contracts = FIN_ContractSelector.getContractByIds(new Set<Id>{
                ((Contract) stdController.getRecord()).Id
        });
        if (!contracts.isEmpty()) {
            this.ctrct = this.contracts[0];
            if (String.isBlank(ctrct.FIN_ParentContract__c) && ctrct.ApprovalStatus__c == 'Approved') {
                contracts.addAll(ctrct.SubContracts__r);
            }
        }
        this.contractsIds = new List<String>();
    }

    public PageReference onReclassify() {
        for (Contract contract : this.contracts) {
            if (contract.ApprovalStatus__c == 'Approved') {
                this.contractsIds.add(contract.Id);
            }
        }
        Database.executeBatch(new ReclassifyUpdateBatch('Order', this.ctrct.FIN_Context__c, this.contractsIds), 500);

        return new PageReference('/' + this.ctrct.Id);
    }

    public PageReference onReprocess() {
        Database.executeBatch(new FIN_ReprocessLibraryAssociationsBatch(this.contracts, this.ctrct.FIN_Context__c, 'OrderItem'));
        Database.executeBatch(new FIN_ReprocessLibraryAssociationsBatch(this.contracts, this.ctrct.FIN_Context__c, 'FIN_Payment__c'));
        Database.executeBatch(new FIN_ReprocessLibraryAssociationsBatch(this.contracts, this.ctrct.FIN_Context__c, 'FIN_PaymentDistribution__c'));
        return new PageReference('/' + ctrct.Id);
    }
}