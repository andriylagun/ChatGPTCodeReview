public with sharing class FIN_ContractAssociationHelper {
    public static void checkForDeactivatedContract(List<ContractAssociation__c> contractAssociations) {
        Set<Id> contractIds = new Set<Id>();
        for (ContractAssociation__c contractAssociation : contractAssociations) {
            contractIds.add(contractAssociation.Contract__c);
        }
        Map<Id, Contract> contracts = new Map<Id, Contract>(FIN_ContractSelector.getContractByIds(contractIds));
        for (ContractAssociation__c contractAssociation : contractAssociations) {
            if (contracts.get(contractAssociation.Contract__c).Status == 'Deactivated' && contractAssociation.ApprovalStatus__c != 'Deactivated') {
                throw new FIN_ContractAssociationException(Constants.CONTRACT_ASSOCIATION_EXCEPTION_MESSAGE);
            }
        }
    }

    public class FIN_ContractAssociationException extends Exception {
    }

}