public with sharing class MasterDataLoadSelector {
    public static List<Master_Data_Load__c> getMasterDataLoadRecordByProcessDate(Date systemLoadLogProcessDate) {
        return [SELECT Id, Sales__c, Payment_Distribution__c, Payment__c, ProcessDate__c, FIN_Region__c,
                Sales__r.FIN_BusinessRuleProcessCompleteStatus__c, Payment__r.FIN_BusinessRuleProcessCompleteStatus__c, Payment_Distribution__r.FIN_BusinessRuleProcessCompleteStatus__c
                FROM Master_Data_Load__c
                WHERE ProcessDate__c = :systemLoadLogProcessDate];
    }

    public static List<Master_Data_Load__c> getMasterDataLoadRecordWithLookupDataById(Id masterDataLoadId) {
        return [SELECT Id, Payment__r.FIN_StagingTableLoadBusinessApproved__c, Sales__r.FIN_StagingTableLoadBusinessApproved__c,
                Payment_Distribution__r.FIN_StagingTableLoadBusinessApproved__c, Payment__r.FIN_Process__c, Sales__r.FIN_Process__c,
                Payment_Distribution__r.FIN_Process__c, FIN_Region__c, Sales__r.isMockup__c, Payment__r.isMockup__c, Payment_Distribution__r.isMockup__c,
                Sales__r.FIN_BusinessRuleStartTime__c, Payment_Distribution__r.FIN_BusinessRuleStartTime__c, Payment__r.FIN_BusinessRuleStartTime__c,
                Sales__r.Id, Payment__r.Id, Payment_Distribution__r.Id, Sales__r.IsBackfillLoad__c, Payment_Distribution__r.IsBackfillLoad__c, Payment__r.IsBackfillLoad__c,
                Sales__r.FIN_BusinessRuleProcessCompleteStatus__c, Payment__r.FIN_BusinessRuleProcessCompleteStatus__c, Payment_Distribution__r.FIN_BusinessRuleProcessCompleteStatus__c
                FROM Master_Data_Load__c
                WHERE Id = :masterDataLoadId];
    }
}