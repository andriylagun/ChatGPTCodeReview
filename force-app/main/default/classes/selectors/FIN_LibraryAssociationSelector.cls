public with sharing class FIN_LibraryAssociationSelector {
    public static List<SBQQ__ContractedPrice__c> getLibraryAssociationsForReclassificationByContextId(String contextId) {
        return [SELECT Id, FIN_ContextName__c, FIN_Context__c, FIN_Fee_Category__c, FIN_ProductName__c, Association_Type__c, FIN_Component_Number__c
        FROM SBQQ__ContractedPrice__c
        WHERE FIN_ContextName__c != NULL AND FIN_ProductName__c != NULL
            AND FIN_Context__c = :contextId AND FIN_Active__c = TRUE];
    }
}