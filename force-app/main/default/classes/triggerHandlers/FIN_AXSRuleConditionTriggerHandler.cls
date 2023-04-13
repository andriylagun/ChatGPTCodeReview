public with sharing class FIN_AXSRuleConditionTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        Set<Id> setlookup = new Set<Id>();
        for (FIN_AXSRuleCondition__c ruleCondition : (List<FIN_AXSRuleCondition__c>) this.triggerNew) {
            setlookup.add(ruleCondition.FIN_SortingRule__c);
        }

        Map<Id, FIN_AXSRuleEngine__c> maplookupObject = new Map<Id, FIN_AXSRuleEngine__c>([
            SELECT Id, FIN_Object__c
            FROM FIN_AXSRuleEngine__c
            WHERE Id IN :setlookup
        ]);

        for (FIN_AXSRuleCondition__c ruleCondition : (List<FIN_AXSRuleCondition__c>) this.triggerNew) {
            ruleCondition.FIN_Object__c = maplookupObject.get(ruleCondition.FIN_SortingRule__c).FIN_Object__c;
        }
    }
}