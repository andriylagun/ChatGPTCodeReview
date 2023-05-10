public with sharing class FIN_UpdateRecordsBatch implements Database.Batchable<SObject> {
    private String query;
    private List<FIN_AXSRuleAction__c> ruleActions;

    public FIN_UpdateRecordsBatch(String query, List<FIN_AXSRuleAction__c> ruleActions) {
        this.query = query;
        this.ruleActions = ruleActions;
    }

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext param1, List<SObject> records) {
        processRuleActions(ruleActions, records);
        Database.update(records, false);
    }

    public void finish(Database.BatchableContext param1) {
    }

    private static void processRuleActions(List<FIN_AXSRuleAction__c> axsRuleActions, List<SObject> records) {
        for (SObject record : records) {
            for (FIN_AXSRuleAction__c action : axsRuleActions) {
                String valueToCheck = String.valueOf(record.get(action.FIN_DestinationField__c));
                if (valueToCheck == null || valueToCheck == 'New' || valueToCheck == 'NotApplicable') {
                    record.put(action.FIN_DestinationField__c, parseValueWithType(action.FIN_DestinationField__c, action.FIN_Object__c, action.FIN_DestinationFieldValue__c));
                }
            }
        }
    }

    private static String getObjectAttributeType(String objectAttribute, String objName) {
        return Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(objectAttribute).getDescribe().getType().name();
    }

    public static Object parseValueWithType(String objectAttribute, String objName, String value) {
        switch on getObjectAttributeType(objectAttribute, Constants.finProcessMap.get(objName)) {
            when 'DOUBLE' {
                return Integer.valueOf(value);
            } when 'BOOLEAN' {
                return Boolean.valueOf(value);
            } when 'DATETIME' {
                return Datetime.valueOf(value);
            } when 'DATE' {
                return Date.valueOf(value);
            }
            when else {
                return value;
            }
        }
    }
}