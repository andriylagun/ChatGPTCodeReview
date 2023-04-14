public with sharing class FIN_AXSRuleConditonSelector {
    public static List<FIN_AXSRuleCondition__c> getRuleConditionsByEnginesIds(List<Id> ruleEngineIds) {
        return [SELECT Id, FIN_RelatedObjectAttribute__c, FIN_Operator__c, FIN_Value__c, FIN_SortingRule__c, FIN_Object_Attribute_Formula__c, FIN_Object__c
                    FROM FIN_AXSRuleCondition__c
                    WHERE FIN_SortingRule__c IN :ruleEngineIds];
    }
}