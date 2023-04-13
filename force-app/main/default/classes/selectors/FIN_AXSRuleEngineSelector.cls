public with sharing class FIN_AXSRuleEngineSelector {
    public static List<FIN_AXSRuleEngine__c> getSettlementRuleEngines(Id settlementRecordTypeId, String region) {
        return [SELECT Id, FIN_Object__c, FIN_Condition__c, FIN_Region__c, FIN_AssociatedContract__c
                    FROM FIN_AXSRuleEngine__c
                    WHERE RecordTypeId = :settlementRecordTypeId AND FIN_Region__c = :region AND isActive__c = TRUE AND ApprovalStatus__c = 'Approved'];
    }
}