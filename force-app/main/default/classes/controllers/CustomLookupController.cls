public class CustomLookupController {

    @AuraEnabled(Cacheable=true)
        public static List<SObject> fetchLookupData(String searchKey, String sObjectApiName, String searchField, String searchObj, String contractId, String type, String objectName, String region) {
        List<SObject> returnList = new List<SObject>();

        if (String.isNotBlank(searchKey)) {
            switch on searchObj {
                when 'Sale', 'Zone' {
                    SOSLQueryBuilder queryBuilder = SOSLQueryBuilder.create()
                        .find(searchKey)
                        .inFields(SOSLQueryBuilder.SearchField.ALL_FIELDS)
                        .queryLimit(5);

                    SOSLQueryBuilder.SOSLReturningBuilder returningBuilder = queryBuilder.returningBuilder(sObjectApiName)
                        .selectClause()
                        .field('Id')
                        .field(searchField)
                        .endSelectSOSL();
                    System.debug(returningBuilder.build());
                    if (contractId != null && contractId != '') {
                        returningBuilder
                            .whereClause()
                            .beginGroup(null)
                            .condition('ApprovalStatus__c', 'Approved', Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .beginGroup(Constants.ConditionOperatorType.AND_CONDITION)
                            .condition('Contract.FIN_ParentContract__c', contractId, Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition('ContractId', contractId, Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.OR_CONDITION)
                            .endGroup()
                            .endGroup();
                    }

                    returningBuilder.endReturning();

                    String query = queryBuilder.build();

                    if (searchObj == 'Sale') {
                        for (List<SObject> objList : Search.query(query)) {
                            for (SObject obj : objList) {
                                returnList.add(obj);
                            }
                        }
                    } else if (searchObj == 'Zone') {
                        Set<String> zones = new Set<String>();

                        for (List<SObject> objList : Search.query(query)) {
                            for (SObject obj : objList) {
                                if (!zones.contains(obj.get('FIN_ZoneDesc__c').toString()) && obj.get('FIN_ZoneDesc__c').toString() != null) {
                                    returnList.add(obj);
                                    zones.add(obj.get('FIN_ZoneDesc__c').toString());
                                }

                                if (returnList.size() == 5) {
                                    break;
                                }
                            }
                        }

                    }
                }
                when 'Event' {
                    SOQLQueryBuilder pdsQueryBuilder = SOQLQueryBuilder.create()
                        .selectClause()
                        .field('FIN_Payment__r.FIN_Order__r.FIN_Event__c')
                        .endSelectSOQL()
                        .fromClause(Schema.SObjectType.FIN_PaymentDistribution__c.getName());

                    if (objectName == 'settlement') {
                        pdsQueryBuilder.whereClause()
                            .beginGroup(null)
                            .condition(FIN_PaymentDistribution__c.Contract__c.getDescribe().getName(), contractId, Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition('FIN_Payment__r.FIN_Order__r.ApprovalStatus__c', 'Approved', Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                            .beginGroup(Constants.ConditionOperatorType.AND_CONDITION)
                            .condition(FIN_PaymentDistribution__c.FIN_Settlement_Status__c.getDescribe().getName(), 'ToBeSettled', Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition(FIN_PaymentDistribution__c.FIN_Settlement_Status__c.getDescribe().getName(), 'Voided', Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.OR_CONDITION)
                            .endGroup()
                            .endGroup()
                            .endWhereSOQL();
                    } else if (objectName == 'invoice') {
                        pdsQueryBuilder.whereClause()
                            .beginGroup(null)
                            .condition(FIN_PaymentDistribution__c.Contract__c.getDescribe().getName(), contractId, Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition('FIN_Payment__r.FIN_Order__r.ApprovalStatus__c', 'Approved', Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                            .beginGroup(Constants.ConditionOperatorType.AND_CONDITION)
                            .condition(FIN_PaymentDistribution__c.Invoices_Status__c.getDescribe().getName(), 'ToBeInvoiced',
                            Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition(FIN_PaymentDistribution__c.Invoices_Status__c.getDescribe().getName(), 'Voided',
                                Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.OR_CONDITION)
                            .endGroup()
                            .endGroup()
                            .endWhereSOQL();
                    }

                    Set<Id> eventIds = new Set<Id>();
                    List<FIN_PaymentDistribution__c> pds = Database.query(pdsQueryBuilder.build());
                    for (FIN_PaymentDistribution__c pd : pds) {
                        eventIds.add(pd.FIN_Payment__r.FIN_Order__r.FIN_Event__c);
                    }

                    SOSLQueryBuilder queryBuilder = SOSLQueryBuilder.create()
                        .find(searchKey)
                        .inFields(SOSLQueryBuilder.SearchField.ALL_FIELDS)
                        .queryLimit(5);

                    SOSLQueryBuilder.SOSLReturningBuilder returningBuilder = queryBuilder.returningBuilder(sObjectApiName)
                        .selectClause()
                        .field('Id')
                        .field(searchField)
                        .endSelectSOSL();

                    returningBuilder
                        .whereClause()
                        .useBindVariablesInQuery(true)
                        .condition('Id', eventIds, Constants.ConditionType.IN_CONDITION, null, null)
                        .endWhere()
                        .endReturning();

                    String query = queryBuilder.build();

                    for (List<SObject> objList : Search.query(query)) {
                        for (SObject obj : objList) {
                            returnList.add(obj);
                        }
                    }

//                    if(contractId != null && contractId != '') {
//                        query += ' WHERE Contract__c = :contractId';
//                    }
//
//                    if (objectName == 'settlement') {
//                        query += ' AND ((FIN_Settlement_Status__c = \'ToBeSettled\' OR FIN_Settlement_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
//                    } else if (objectName == 'invoice') {
//                        query += ' AND ((Invoices_Status__c = \'ToBeInvoiced\' OR Invoices_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
//                    } else if (objectName == 'journalizing') {
//                        query += ' WHERE FIN_Journalizing_Status__c = \'ToBePosted\' AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\' ';
//                    }
//
//                    List<FIN_PaymentDistribution__c> eventsFromPdList = new List<FIN_PaymentDistribution__c>();
//                    eventsFromPdList = Database.query(query);
//                    Set<Id> eventIds = new Set<Id>();
//
//                    for (FIN_PaymentDistribution__c eventPD : eventsFromPdList) {
//                        eventIds.add(eventPD.FIN_Event__c);
//                    }
//
//                    String query2 = 'SELECT Id, Name FROM Campaign WHERE Id IN :eventIds ';
//                    query2 += ' AND :searchField LIKE \'%:searchKey%\' ORDER BY Name DESC LIMIT 5';
//
//                    List<Campaign> evnts = new List<Campaign>();
//                    evnts = Database.query(query2.replace(':searchField', searchField).replace(':searchKey', searchKey));
                }
                when 'Context' {
                    Set<Id> contextIds = new Set<Id>();

                    if (type == FIN_PaymentDistribution__c.SObjectType.getDescribe().getName()) {
                        SOQLQueryBuilder pdsQueryBuilder = SOQLQueryBuilder.create()
                            .selectClause()
                            .field('FIN_ContextName__c')
                            .field('FIN_ContextName__r.FIN_Active__c')
                            .endSelectSOQL()
                            .fromClause(Schema.SObjectType.FIN_PaymentDistribution__c.getName())
                            .whereClause()
                            .condition('FIN_Region__c', region, Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition('FIN_ContextName__r.FIN_Active__c', true, Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                            .endWhereSOQL()
                            .limitForQuery(5000);

                        List<FIN_PaymentDistribution__c> pds = Database.queryWithBinds(pdsQueryBuilder.build(), pdsQueryBuilder.getBindVariables(), AccessLevel.USER_MODE);
                        for (FIN_PaymentDistribution__c pd : pds) {
                            if (!contextIds.contains(pd.FIN_ContextName__c)) {
                                contextIds.add(pd.FIN_ContextName__c);
                            }
                        }
                    } else if (type == FIN_Payment__c.SObjectType.getDescribe().getName()) {
                        SOQLQueryBuilder paymentsQueryBuilder = SOQLQueryBuilder.create()
                            .selectClause()
                            .field('FIN_Order__r.FIN_OrderContext__c')
                            .field('FIN_Order__r.FIN_OrderContext__r.FIN_Active__c')
                            .endSelectSOQL()
                            .fromClause(Schema.SObjectType.FIN_Payment__c.getName())
                            .whereClause()
                            .condition('FIN_Region__c', region, Constants.ConditionType.EQUALS_CONDITION, null, null)
                            .condition('FIN_Order__r.FIN_OrderContext__r.FIN_Active__c', true, Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
                            .endWhereSOQL();

                        List<FIN_Payment__c> payments = Database.queryWithBinds(paymentsQueryBuilder.build(), paymentsQueryBuilder.getBindVariables(), AccessLevel.USER_MODE);
                        for (FIN_Payment__c payment : payments) {
                            if (!contextIds.contains(payment.FIN_Order__r.FIN_OrderContext__c)) {
                                contextIds.add(payment.FIN_Order__r.FIN_OrderContext__c);
                            }
                        }
                    }

                    SOSLQueryBuilder queryBuilder = SOSLQueryBuilder.create()
                        .find(searchKey)
                        .inFields(SOSLQueryBuilder.SearchField.ALL_FIELDS)
                        .queryLimit(5);

                    SOSLQueryBuilder.SOSLReturningBuilder returningBuilder = queryBuilder.returningBuilder(sObjectApiName)
                        .selectClause()
                        .field('Id')
                        .field(searchField)
                        .endSelectSOSL();

                    returningBuilder
                        .whereClause()
                        .useBindVariablesInQuery(true)
                        .condition('Id', contextIds, Constants.ConditionType.IN_CONDITION, null, null)
                        .endWhere()
                        .endReturning();

                    String query = queryBuilder.build();

                    for (List<SObject> objList : Search.query(query)) {
                        for (SObject obj : objList) {
                            returnList.add(obj);
                        }
                    }
                }
                when 'Contract' {
                    SOSLQueryBuilder queryBuilder = SOSLQueryBuilder.create()
                        .find(searchKey)
                        .inFields(SOSLQueryBuilder.SearchField.ALL_FIELDS)
                        .queryLimit(5);

                    SOSLQueryBuilder.SOSLReturningBuilder returningBuilder = queryBuilder.returningBuilder(sObjectApiName)
                        .selectClause()
                        .field('Id')
                        .field(searchField)
                        .endSelectSOSL();

                    returningBuilder
                        .whereClause()
                        .condition('FIN_Region__c', region, Constants.ConditionType.EQUALS_CONDITION, null, null)
                        .condition('FIN_ActiveStatus__c', true, Constants.ConditionType.EQUALS_CONDITION, null, Constants.ConditionOperatorType.AND_CONDITION)
//                        .negative('ActivatedDate', Date.Today(), Constants.ConditionType.GREATER_THEN, null, Constants.ConditionOperatorType.AND_CONDITION)
                        .endWhere()
                        .endReturning();

                    String query = queryBuilder.build();

                    for (List<SObject> objList : Search.query(query)) {
                        for (SObject obj : objList) {
                            returnList.add(obj);
                        }
                    }
                }
            }
        }

        System.debug('returnList: ' + returnList);
        return returnList;
    }

    @AuraEnabled(Cacheable=true)
    public static SObject fetchDefaultRecord(String recordId, String sObjectApiName, String searchField) {
        String sRecId = recordId;
        String sQuery = 'Select Id, ' + searchField + ' From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        for (SObject obj : Database.query(sQuery)) {
            System.debug('obj' + obj);
            return obj;
        }
        return null;
    }
}