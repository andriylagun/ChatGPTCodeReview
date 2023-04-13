public with sharing class FIN_ContractHelper {
    public static void processDeactivatedContracts(List<Contract> contracts) {
        Set<Id> contractIds = new Set<Id>();
        List<Contract> subContractsToUpdate = new List<Contract>();
        List<ContractAssociation__c> contractAssociationsToUpdate = new List<ContractAssociation__c>();
        for (Contract contract : contracts) {
            if (contract.Status == 'Deactivated') {
                contractIds.add(contract.Id);
            }
        }
        if (!contractIds.isEmpty()) {
            List<Contract> contractsDataWithLookups = FIN_ContractSelector.getContractByIds(contractIds);
            contractIds.clear();
            for (Contract contract : contractsDataWithLookups) {
                if (!contract.SubContracts__r.isEmpty()) {
                    for (Contract subContract : contract.SubContracts__r) {
                        contractIds.add(subContract.Id);
                        subContract.Status = 'Deactivated';
                        subContractsToUpdate.add(subContract);
                    }
                }
                contractIds.add(contract.Id);
            }
            List<ContractAssociation__c> contractAssociations = FIN_ContractAssociationSelector.getNotDeactivatedContractAssociationsByContractIds(contractIds);
            for (ContractAssociation__c contractAssociation : contractAssociations) {
                contractAssociation.ApprovalStatus__c = 'Deactivated';
                contractAssociationsToUpdate.add(contractAssociation);
            }
            update contractAssociationsToUpdate;
            update subContractsToUpdate;
        }
    }

    public static void processActivatedContractsCAs(Map<Id, Contract> oldMap, List<Contract> newContractsList) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract ctrct : newContractsList) {
            if (oldMap.get(ctrct.Id).Status == 'Deactivated' && ctrct.Status != 'Deactivated') {
                contractIds.add(ctrct.Id);
            }
        }
        List<ContractAssociation__c> contractAssociations = FIN_ContractAssociationSelector.getDeactivatedContractAssociationsByContractIds(contractIds);
        for (ContractAssociation__c ca : contractAssociations) {
            ca.ApprovalStatus__c = 'New';
        }
        update contractAssociations;
    }
}