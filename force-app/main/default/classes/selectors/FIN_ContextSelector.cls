public with sharing class FIN_ContextSelector {
    public static List<FIN_Context__c> getAllActiveContexts() {
        return [SELECT Id, Context_ID__c FROM FIN_Context__c WHERE FIN_Active__c = TRUE];
    }
}