public with sharing class FIN_ContractSelector {
    public static List<Contract> getContractByIds(Set<Id> contractIds) {
        return [
                SELECT Id, FIN_ParentContract__c, Status, ApprovalStatus__c, FIN_Context__c, (SELECT Id, Status, ApprovalStatus__c, FIN_Context__c FROM SubContracts__r)
                FROM Contract
                WHERE Id in :contractIds
        ];
    }
}