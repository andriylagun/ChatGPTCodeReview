public with sharing class FIN_SystemDataLoadLogSelector {
    public static List<FIN_SystemDataLoadLog__c> getSystemDataLoadLogByIdIn(List<Id> systemDataLoadLogIds) {
        return [SELECT Id, FIN_StagingTableLoadBusinessApproved__c, FIN_Process__c, FIN_Region__c, isMockup__c, FIN_RecordsProcessed__c, FIN_BusinessRuleProcessCompleteStatus__c,
                FIN_ReturnedFromSaleTransactions__c, FIN_BusinessRuleStartTime__c
                FROM FIN_SystemDataLoadLog__c
                WHERE Id IN :systemDataLoadLogIds];
    }
}