public with sharing class FIN_AXSRuleActionSelector {
    public static List<FIN_AXSRuleAction__c> getRuleActionsByEnginesIds(List<Id> ruleEngineIds) {
        return [SELECT Id, FIN_DestinationField__c, FIN_DestinationFieldValue__c, FIN_Object__c, FIN_SortingRule__c, FIN_SortingRule__r.Name
                    FROM FIN_AXSRuleAction__c
                    WHERE FIN_SortingRule__c IN :ruleEngineIds];
    }
}
