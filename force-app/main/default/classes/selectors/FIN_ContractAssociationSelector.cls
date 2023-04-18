public with sharing class FIN_ContractAssociationSelector {

    public static List<ContractAssociation__c> getNotDeactivatedContractAssociationsByContractIds(Set<Id> contractIds) {
        return [SELECT Id, ApprovalStatus__c FROM ContractAssociation__c WHERE Contract__c IN :contractIds AND ApprovalStatus__c != 'Deactivated'];
    }

    public static List<ContractAssociation__c> getDeactivatedContractAssociationsByContractIds(Set<Id> contractIds) {
        return [SELECT Id, ApprovalStatus__c FROM ContractAssociation__c WHERE Contract__c IN :contractIds AND ApprovalStatus__c = 'Deactivated'];
    }

    public static List<ContractAssociation__c> getAllContractAssociationsByContextId(String contextId) {
        return [SELECT Id, Contract__c, Contract__r.AccountId, Contract__r.Pricebook2Id, Context__c, FIN_Venue__c, Client__c, FIN_AXS_Event__c, FIN_Event_Zone__r.Name, FIN_Event_Zone__c, FIN_ContractAssociationMatchingLevel__c,
                Contract__r.EndDate, Contract__r.StartDate
        FROM ContractAssociation__c
        WHERE Context__c = :contextId AND Client__c != NULL AND ApprovalStatus__c = 'Approved'
        ORDER BY FIN_ContractAssociationMatchingLevel__c DESC];
    }

    public static List<ContractAssociation__c> getAllContractAssociationsByContractIdInAndContextId(String contextId, List<String> contractIds) {
        return [SELECT Id, Contract__c, Contract__r.AccountId, Contract__r.Pricebook2Id, Context__c, FIN_Venue__c, Client__c, FIN_AXS_Event__c, FIN_Event_Zone__r.Name, FIN_ContractAssociationMatchingLevel__c,
                Contract__r.EndDate, Contract__r.StartDate
        FROM ContractAssociation__c
        WHERE Contract__c IN :contractIds AND Contract__r.Status != 'Deactivated' AND ApprovalStatus__c = 'Approved'
        ORDER BY FIN_ContractAssociationMatchingLevel__c DESC];
    }
}