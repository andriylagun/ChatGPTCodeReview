public with sharing class FIN_AXSRuleEngineService {
    public static void markRecordsOnHerokuAsProcessed(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        if (systemDataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c == 'Success Heroku') {
            if (systemDataLoadLog.FIN_Process__c == 'Sales' && !systemDataLoadLog.FIN_ReturnedFromSaleTransactions__c) {
                FIN_SystemDataLoadLogService.makeSimpleHttpCallout(JSON.serialize(new Map<String, String>{
                        'systemDataLoadLogId' => systemDataLoadLog.Id
                }), 'callout:Process_Sales_Transactions_Heroku');
            } else {
                markInsertedRecordsAsProcessed(systemDataLoadLog);
            }
        }
    }

    public static void markInsertedRecordsAsProcessed(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        FIN_SystemDataLoadLogService.makeSimpleHttpCallout(JSON.serialize(new Map<String, String>{
                'systemDataLoadLogId' => systemDataLoadLog.Id
        }),
                'callout:Mark_Processed_Records_Heroku');
    }

    public static void processSettlementRuleEngineFromSystemDataLoadLog(FIN_SystemDataLoadLog__c systemDataLoadLog) {
        FIN_SystemDataLoadLog__c systemDataLoad = new FIN_SystemDataLoadLog__c(Id = systemDataLoadLog.Id);
        try {
            processSettlementRules(systemDataLoadLog.FIN_Region__c);
            systemDataLoad.FIN_SalesforceRulesEndTime__c = System.now();
            systemDataLoad.FIN_SalesforceRulesStatus__c = 'Success';
            update systemDataLoad;
        } catch (AuraHandledException e) {
            systemDataLoad.FIN_SalesforceRulesEndTime__c = System.now();
            systemDataLoad.FIN_SalesforceRulesStatus__c = 'Failure';
            update systemDataLoad;
            Logger.log(e, systemDataLoadLog.FIN_Process__c, systemDataLoadLog.FIN_Region__c);
        }
    }

    public static void processSettlementRules(String finRegion) {
        Id settlementRecordTypeId = Schema.SObjectType.FIN_AXSRuleEngine__c.getRecordTypeInfosByName().get('Settlement').getRecordTypeId();
        List<FIN_AXSRuleEngine__c> ruleEngines = FIN_AXSRuleEngineSelector.getSettlementRuleEngines(settlementRecordTypeId, finRegion);
        Map<String, List<AXSRuleEngineWrapper>> ruleEnginesMap = prepareRuleEngineToProcess(ruleEngines);
        for (List<AXSRuleEngineWrapper> ruleEngineWrappers : ruleEnginesMap.values()) {
            for (AXSRuleEngineWrapper ruleEngineWrapper : ruleEngineWrappers) {
                String operator = ruleEngineWrapper.finCondition;
                String finObject = ruleEngineWrapper.finObject;
                String conditions = Constants.getContractFieldFromObject(Constants.finProcessMapForSettlement.get(ruleEngineWrapper.finObject)) + ' = \'' + ruleEngineWrapper.associatedContract + '\'';
                String fieldList = '';
                if (ruleEngineWrapper.ruleConditions != null && !ruleEngineWrapper.ruleConditions.isEmpty()) {
                    conditions += (ruleEngineWrapper.ruleConditions.isEmpty() ? '' : ' AND ' + String.join(prepareConditions(ruleEngineWrapper.ruleConditions), ' ' + operator + ' '));
                }
                if (ruleEngineWrapper.ruleActions != null && !ruleEngineWrapper.ruleActions.isEmpty()) {
                    fieldList = String.join(prepareFieldsList(ruleEngineWrapper.ruleActions), ', ');
                    List<String> destinationConditions = new List<String>();
                    for (FIN_AXSRuleAction__c ruleAction : ruleEngineWrapper.ruleActions) {
                        String condition = !Constants.idFieldsFromRuleAction.contains(ruleAction.FIN_DestinationField__c) ? ruleAction.FIN_DestinationField__c + ' = \'New\' OR ' : '';
                        destinationConditions.add('(' + condition + ruleAction.FIN_DestinationField__c + ' = NULL)');
                    }
                    conditions += ' AND ' + (destinationConditions.isEmpty() ? '' : '(' + String.join(destinationConditions, ' AND ')) + ')';
                }
                if (!String.isBlank(fieldList)) {
                    String query = Constants.STANDART_SELECT_QUERY.replace(':fields', fieldList)
                            .replace(':object', Constants.finProcessMapForSettlement.get(finObject))
                            .replace(':conditions', conditions);
                    if (String.isBlank(conditions)) {
                        query = query.replace('WHERE', '');
                    }
                    System.debug(query);
                    Database.executeBatch(new FIN_UpdateRecordsBatch(query, ruleEngineWrapper.ruleActions));
                }
            }
        }
    }

    private static Map<String, List<AXSRuleEngineWrapper>> prepareRuleEngineToProcess(List<FIN_AXSRuleEngine__c> ruleEngines) {
        List<Id> ruleEnginesIds = new List<Id>();
        for (FIN_AXSRuleEngine__c ruleEngine : ruleEngines) {
            ruleEnginesIds.add(ruleEngine.Id);
        }
        Map<String, List<AXSRuleEngineWrapper>> ruleEngineWrapperMap = new Map<String, List<AXSRuleEngineWrapper>>();
        List<FIN_AXSRuleCondition__c> ruleConditions = FIN_AXSRuleConditonSelector.getRuleConditionsByEnginesIds(ruleEnginesIds);
        List<FIN_AXSRuleAction__c> ruleActions = FIN_AXSRuleActionSelector.getRuleActionsByEnginesIds(ruleEnginesIds);
        for (FIN_AXSRuleEngine__c ruleEngine : ruleEngines) {
            Map<Id, List<FIN_AXSRuleCondition__c>> axsRuleConditions = new Map<Id, List<FIN_AXSRuleCondition__c>>();
            Map<Id, List<FIN_AXSRuleAction__c>> axsRuleActions = new Map<Id, List<FIN_AXSRuleAction__c>>();
            for (FIN_AXSRuleCondition__c ruleCondition : ruleConditions) {
                if (axsRuleConditions.containsKey(ruleCondition.FIN_SortingRule__c)) {
                    axsRuleConditions.get(ruleCondition.FIN_SortingRule__c).add(ruleCondition);
                } else {
                    axsRuleConditions.put(ruleCondition.FIN_SortingRule__c, new List<FIN_AXSRuleCondition__c>{
                            ruleCondition
                    });
                }
            }
            for (FIN_AXSRuleAction__c ruleAction : ruleActions) {
                if (axsRuleActions.containsKey(ruleAction.FIN_SortingRule__c)) {
                    axsRuleActions.get(ruleAction.FIN_SortingRule__c).add(ruleAction);
                } else {
                    axsRuleActions.put(ruleAction.FIN_SortingRule__c, new List<FIN_AXSRuleAction__c>{
                            ruleAction
                    });
                }
            }
            if (ruleEngineWrapperMap.containsKey(ruleEngine.FIN_Object__c)) {
                ruleEngineWrapperMap.get(ruleEngine.FIN_Object__c).add(new AXSRuleEngineWrapper(ruleEngine,
                        axsRuleConditions.get(ruleEngine.Id), axsRuleActions.get(ruleEngine.Id)));
            } else {
                ruleEngineWrapperMap.put(ruleEngine.FIN_Object__c, new List<AXSRuleEngineWrapper>{
                        new AXSRuleEngineWrapper(ruleEngine,
                                axsRuleConditions.get(ruleEngine.Id), axsRuleActions.get(ruleEngine.Id))
                });
            }
        }
        return ruleEngineWrapperMap;
    }

    private static List<String> prepareConditions(List<FIN_AXSRuleCondition__c> ruleConditions) {
        List<String> conditions = new List<String>();
        for (FIN_AXSRuleCondition__c condition : ruleConditions) {
            if (condition.FIN_Value__c != null && condition.FIN_Object_Attribute_Formula__c != null && condition.FIN_Operator__c != null) {
                conditions.add(prepareCondition(condition));
            }
        }
        return conditions;
    }

    private static List<String> prepareFieldsList(List<FIN_AXSRuleAction__c> ruleActions) {
        List<String> fieldsList = new List<String>();
        for (FIN_AXSRuleAction__c ruleAction : ruleActions) {
            fieldsList.add(ruleAction.FIN_DestinationField__c);
        }
        return fieldsList;
    }

    private static String prepareCondition(FIN_AXSRuleCondition__c ruleCondition) {
        FIN_Object_and_Fields__mdt objectFromMetadata = FIN_Object_and_Fields__mdt.getAll().get(ruleCondition.FIN_Object__c);
        String condition = ruleCondition.FIN_Object_Attribute_Formula__c;
        switch on ruleCondition.FIN_Operator__c {
            when '=' {
                condition += ruleCondition.FIN_Operator__c + getValueInCorrectFormat(ruleCondition.FIN_Value__c, getObjectAttributeType(ruleCondition.FIN_RelatedObjectAttribute__c, objectFromMetadata != null ?
                        objectFromMetadata.DestinationObject__c : Constants.finProcessMapForSettlement.get(ruleCondition.FIN_Object__c)));
            } when '<>' {
                condition += '!=:value';
            } when 'contains' {
                condition += 'LIKE \'%:value%\'';
            }
        }
        return condition.replace(':value', ruleCondition.FIN_Value__c);
    }

    private static Object getValueInCorrectFormat(String value, String attributeType) {
        switch on attributeType {
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
                return '\'' + value + '\'';
            }
        }
    }

    private static String getObjectAttributeType(String objectAttribute, String objName) {
        return Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(objectAttribute).getDescribe().getType().name();
    }

    public class AXSRuleEngineWrapper {
        public Id id;
        public String finObject;
        public String finCondition;
        public String finRegion;
        public Id associatedContract;
        public List<FIN_AXSRuleCondition__c> ruleConditions;
        public List<FIN_AXSRuleAction__c> ruleActions;

        public AXSRuleEngineWrapper(FIN_AXSRuleEngine__c ruleEngine, List<FIN_AXSRuleCondition__c> conditions, List<FIN_AXSRuleAction__c> actions) {
            this.id = ruleEngine.Id;
            this.finObject = ruleEngine.FIN_Object__c;
            this.finCondition = ruleEngine.FIN_Condition__c;
            this.finRegion = ruleEngine.FIN_Region__c;
            this.associatedContract = ruleEngine.FIN_AssociatedContract__c;
            this.ruleConditions = conditions;
            this.ruleActions = actions;
        }
    }
}